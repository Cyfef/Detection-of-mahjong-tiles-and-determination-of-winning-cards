function train_model()
    % train_model 加载降维后特征，并使用 KNN/SVM/GMM 三种模型训练，保存每种模型及类别标签到 models 文件夹中。

    % 加载之前保存的特征和标签
    load('features.mat', 'features', 'label_list', 'coeff', 'explained');

    % 将字符串标签映射到数字编码
    unique_labels = unique(label_list);
    label_nums    = zeros(length(label_list), 1);
    for i = 1:length(label_list)
        label_nums(i) = find(strcmp(label_list{i}, unique_labels));
    end

    %----- KNN 分类器训练 -----%
    knn_model = fitcknn(features, label_nums, 'NumNeighbors', 3);
    save('models/knn_model.mat', 'knn_model', 'unique_labels');

    %----- SVM 分类器训练（ECOC） -----%
    svm_model = fitcecoc(features, label_nums);  % 多类 ECOC SVM
    save('models/svm_model.mat', 'svm_model', 'unique_labels');

    %----- GMM 分类器训练 -----%
    num_classes = length(unique_labels);
    gmm_models  = cell(num_classes, 1);
    for c = 1:num_classes
        idx  = (label_nums == c);
        data = features(idx, :);
        % 仅当样本数大于特征维度时训练 GMM
        if size(data,1) > size(data,2)
            gmm_models{c} = fitgmdist(data, 1);
        else
            warning('类别 %d 样本数不足，跳过 GMM。', c);
            gmm_models{c} = [];
        end
    end
    save('models/gmm_model.mat', 'gmm_models', 'unique_labels');
end