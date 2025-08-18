function preprocess_images()
    % preprocess_images 将增强后的原始图像进行灰度化、二值化、去噪和统一大小，并保存到新的 processed 文件夹结构中。

    % 输入与输出根目录
    input_folder  = 'dataset/train/';      % 增强后数据
    output_folder = 'dataset/processed/';  % 预处理后数据
    image_size    = [64, 64];              % 统一 resize 大小

    % 获取所有类别目录
    classes = dir(input_folder);
    for i = 1:length(classes)
        class_name = classes(i).name;
        % 仅处理文件夹且排除隐藏目录
        if classes(i).isdir && ~startsWith(class_name, '.')
            input_class_path  = fullfile(input_folder,  class_name);
            output_class_path = fullfile(output_folder, class_name);

            % 若输出目录不存在，则创建
            if ~exist(output_class_path, 'dir')
                mkdir(output_class_path);
            end

            % 遍历此类别下所有 png 图像
            images = dir(fullfile(input_class_path, '*.png'));
            for j = 1:length(images)
                img_name = images(j).name;
                img_path = fullfile(input_class_path, img_name);
                img = imread(img_path);             % 读取图像

                % 1) 灰度化：若为彩色图，则转为灰度
                if size(img, 3) == 3
                    img_gray = rgb2gray(img);
                else
                    img_gray = img;
                end

                % 2) 自适应二值化：突出牌面花纹
                bw = imbinarize(img_gray, 'adaptive');

                % 3) 中值滤波：去除椒盐噪声，保留边缘
                bw_denoised = medfilt2(bw, [3, 3]);

                % 4) Resize：统一图像大小，方便后续批量处理
                resized = imresize(bw_denoised, image_size);

                % 保存预处理后图像
                out_path = fullfile(output_class_path, img_name);
                imwrite(resized, out_path);
            end
        end
    end
end