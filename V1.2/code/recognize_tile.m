function label = recognize_tile(tile_img, model_type)
    % recognize_tile 对单张牌图像进行预处理、特征提取并调用指定模型预测标签
    % 输入:
    %   tile_img   - 原始彩色或灰度图像矩阵
    %   model_type - 字符串，'knn'|'svm'|'gmm'（默认 'gmm'）
    % 输出:
    %   label      - 预测的类别标签（字符）

    if nargin < 2
        model_type = 'gmm';
    end

    % 1) 预处理：灰度化、统一大小、中值滤波去噪
    image_size = [64,64];
    if size(tile_img,3) == 3
        tile_img = rgb2gray(tile_img);
    end
    tile_img = imresize(tile_img, image_size);
    tile_img = medfilt2(tile_img, [3,3]);

    % 2) 特征提取：HOG + FFT
    hog_feat = single(extractHOGFeatures(tile_img, 'CellSize', [8 8]));
    fft_feat = abs(fft2(tile_img));
    fft_feat = single(imresize(fft_feat, [8,8]));
    fft_feat = reshape(fft_feat, 1, []);
    feat     = [hog_feat, fft_feat];

    % 3) PCA 投影（若存在 features.mat）
    if exist('features.mat','file')
        load('features.mat','coeff','explained','mu');
        mu    = single(mu);
        coeff = single(coeff);
        % 确保维度匹配
        num_components = find(cumsum(explained)>=95,1);
        feat_centered = feat - mu;
        feat = feat_centered * coeff(:,1:num_components);
    end

    % 4) 根据模型类型转换数据类型
    if strcmpi(model_type,'knn')
        feat = double(feat);
    else
        feat = single(feat);
    end

    % 5) 调用分类模型进行预测
    switch lower(model_type)
        case 'knn'
            load('models/knn_model.mat','knn_model','unique_labels');
            [~,scores] = predict(knn_model, feat);
            [~,idx] = max(scores);
            label = unique_labels{idx};
        case 'svm'
            load('models/svm_model.mat','svm_model','unique_labels');
            idx = predict(svm_model, feat);
            label = unique_labels{idx};
        case 'gmm'
            load('models/gmm_model.mat','gmm_models','unique_labels');
            % 选择最大概率的 GMM 模型
            max_p = -Inf;
            label = '未知';
            for ii = 1:length(gmm_models)
                gm = gmm_models{ii};
                if isempty(gm), continue; end
                p = pdf(gm, double(feat));
                if p > max_p
                    max_p = p;
                    label = unique_labels{ii};
                end
            end
        otherwise
            error('未知模型类型：%s', model_type);
    end
end