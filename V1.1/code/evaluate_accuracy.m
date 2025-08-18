function [accuracy, per_class_accuracy] = evaluate_accuracy(model_type)
    % evaluate_accuracy 对所有 processed 图像按指定模型进行识别并统计准确率
    % 输入:
    %   model_type - 'knn'|'svm'|'gmm'（默认 'gmm'）
    % 输出:
    %   accuracy           - 总体准确率
    %   per_class_accuracy - containers.Map，每个类别的准确率

    if nargin < 1
        model_type = 'gmm';
    end
    data_folder = 'dataset/processed/';
    classes     = dir(data_folder);
    classes     = classes([classes.isdir]&~startsWith({classes.name},'.'));

    total_correct = 0;
    total_count   = 0;
    per_class_accuracy = containers.Map();

    % 遍历每个类别文件夹
    for i = 1:length(classes)
        class_name = classes(i).name;
        imgs = dir(fullfile(data_folder, class_name, '*.png'));
        class_correct = 0;

        % 遍历此类别下所有图像
        for j = 1:length(imgs)
            img = imread(fullfile(data_folder, class_name, imgs(j).name));
            % 调用识别函数得到预测标签
            pred = recognize_tile(img, model_type);
            % 与真实标签对比
            if strcmp(pred, class_name)
                class_correct = class_correct + 1;
                total_correct = total_correct + 1;
            end
            total_count = total_count + 1;
        end

        % 计算此类别准确率并存储
        per_class_accuracy(class_name) = class_correct / length(imgs);
    end

    % 计算总体准确率
    accuracy = total_correct / total_count;

    % 打印结果
    fprintf('\n【模型: %s】 总体准确率: %.2f%% (%d/%d)\n', upper(model_type), 100*accuracy, total_correct, total_count);
    fprintf('--- 每类准确率 ---\n');
    keys = per_class_accuracy.keys;
    for i = 1:length(keys)
        fprintf('%s: %.2f%%\n', keys{i}, 100*per_class_accuracy(keys{i}));
    end
end
