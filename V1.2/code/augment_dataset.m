function augment_dataset(num_augmented)
    % 输入参数:num_augmented - 每张原图生成的增强图像数量（默认5）

    if nargin < 1
        % 如果未传入 num_augmented，则默认每类生成5张增强图
        num_augmented = 5;
    end

    % 定义训练数据所在根目录
    input_folder = 'dataset/train/';
    % 获取根目录下的所有文件夹信息（包括文件与文件夹）
    classes = dir(input_folder);
    % 过滤只保留子文件夹，排除隐藏目录（如 . 和 ..）
    classes = classes([classes.isdir] & ~startsWith({classes.name}, '.'));

    % 遍历每个类别文件夹
    for i = 1:length(classes)
        class_name = classes(i).name;                          % 当前类别名称
        class_path = fullfile(input_folder, class_name);       % 类别文件夹完整路径

        % 获取该文件夹下所有 .png 文件列表
        png_files = dir(fullfile(class_path, '*.jpg'));
        if isempty(png_files)
            % 如未找到任何png图像，发出警告并跳过此类别
            warning('跳过 %s，未找到 .jpg 文件', class_name);
            continue;
        end

        % 遍历此类别下的每张原始图像
        for k = 1:length(png_files)
            original_img_path = fullfile(class_path, png_files(k).name);
            img = imread(original_img_path);                     % 读取图像

            % 如果是彩色图，将其转为灰度，保留亮度信息
            if size(img, 3) == 3
                img = rgb2gray(img);
            end

            % 保存一个未增强的图像副本，标记为 aug0_
            imwrite(img, fullfile(class_path, sprintf('aug0_%s', png_files(k).name)));

            % 进行多次增强，生成 num_augmented 张变体
            for j = 1:num_augmented
                aug_img = double(img);   % 转为 double 类型，便于后续数值变换

                % 1) 随机旋转：角度范围[-10, 10]度 
                angle = randi([-10, 10], 1);
                aug_img = imrotate(aug_img, angle, 'crop');

                % 2) 随机缩放：缩放比例范围[0.9, 1.1] 
                scale = 0.9 + 0.2 * rand();
                aug_img = imresize(aug_img, scale);         % 缩放
                aug_img = imresize(aug_img, size(img));     % 再缩回原始大小

                % 3) 随机亮度扰动：±20 灰度值
                brightness = 40 * (rand() - 0.5);
                aug_img = aug_img + brightness;

                % 4) 添加高斯噪声：均值0、方差0.002
                aug_img = imnoise(uint8(aug_img), 'gaussian', 0, 0.002);

                % 5) 限制像素值在 [0,255] 区间并转回 uint8
                aug_img = uint8(min(max(double(aug_img), 0), 255));

                % 保存增强后的图，文件名带上 aug 序号
                save_path = fullfile(class_path, sprintf('aug%d_%s', j, png_files(k).name));
                imwrite(aug_img, save_path);
            end

            % 控制台输出，本张原图增强完成情况
            fprintf('✅ 类别 %s 增强完成，文件 %s 生成 %d 张图像\n', ...
                    class_name, png_files(k).name, num_augmented + 1);
        end
    end
end