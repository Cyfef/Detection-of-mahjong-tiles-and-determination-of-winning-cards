function feature_extraction()
    % feature_extraction 从 processed 文件夹中读取每张图像，提取 HOG 和 FFT 特征，并对所有图像执行 PCA 降维。
    % 最终将特征矩阵和标签列表保存到 features.mat。

    input_folder = 'dataset/processed/';
    classes      = dir(input_folder);
    feature_list = [];
    label_list   = {};

    %% HOG 参数设置
    hog_cell_size = [8, 8];

    % 遍历每个类别
    for i = 1:length(classes)
        class_name = classes(i).name;
        if classes(i).isdir && ~startsWith(class_name, '.')
            class_path = fullfile(input_folder, class_name);
            images     = dir(fullfile(class_path, '*.jpg'));

            for j = 1:length(images)
                img_path = fullfile(class_path, images(j).name);
                img      = imread(img_path);  % 读取预处理后的二值图

                % 1) 提取 HOG 特征，输出向量 feat
                feat = extractHOGFeatures(img, 'CellSize', hog_cell_size);

                % 2) 提取傅里叶特征：FFT->取幅值->缩放至 8x8 -> reshape
                fft_img  = abs(fft2(double(img)));
                fft_feat = reshape(imresize(fft_img, [8,8]), 1, []);

                % 3) 合并特征向量
                final_feat = [feat, fft_feat];

                % 4) 累加到总体特征列表和标签列表
                feature_list(end+1, :) = final_feat;
                label_list{end+1}      = class_name;
            end
        end
    end

    %% PCA 降维处理
    mu        = mean(feature_list, 1);                     % 计算每列均值
    [coeff, score, ~, ~, explained] = pca(feature_list);    % PCA 分解
    % 找到累计方差>95%的主成分数
    num_components = find(cumsum(explained) > 95, 1);
    features = score(:, 1:num_components);                 % 降维后特征

    % 保存特征、标签及 PCA 模型参数
    save('features.mat', 'features', 'label_list', 'coeff', 'explained', 'mu');
end
