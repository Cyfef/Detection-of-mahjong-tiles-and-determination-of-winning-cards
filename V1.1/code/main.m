function main()
    % 1. 数据集增强
    disp('正在进行数据增强...');
    augment_dataset(15);  % 每类生成15张图像
    disp('数据增强完成.✅');

    % 2. 图像预处理
    disp('正在进行图像预处理...');
    preprocess_images();
    disp('图像预处理完成.✅');

    % 3. 特征提取
    disp('正在提取特征...');
    feature_extraction();
    disp('特征提取完成.✅');

    % 4. 训练模型
    disp('正在训练模型...');
    train_model();
    disp('模型训练完成.✅');

     % 5. 评估各个模型的准确率
    model_types = {'knn', 'svm', 'gmm'};
    accuracy_results = {};

    for i = 1:length(model_types)
        model_type = model_types{i};
        disp(['正在评估模型: ', model_type]);
        [acc, per_class_accuracy] = evaluate_accuracy(model_type);
        
        % 存储每种模型的准确率数据
        accuracy_results{i}.model_type = model_type;
        accuracy_results{i}.overall_accuracy = acc;
        accuracy_results{i}.per_class_accuracy = per_class_accuracy;
    end

    % 6. 保存准确率数据到 Excel 文件
    accuracy_table = [];
    for i = 1:length(model_types)
        model_data = accuracy_results{i};
        model_type = model_data.model_type;
        overall_accuracy = model_data.overall_accuracy;
        per_class_accuracy = model_data.per_class_accuracy;
        
        % 汇总整体准确率
        accuracy_table = [accuracy_table; {model_type, 'Overall', overall_accuracy}];
        
        % 汇总每个类别的准确率
        class_names = keys(per_class_accuracy);
        for j = 1:length(class_names)
            class_name = class_names{j};
            class_accuracy = per_class_accuracy(class_name);
            accuracy_table = [accuracy_table; {model_type, class_name, class_accuracy}];
        end
    end

    % 将数据写入 Excel
    writetable(cell2table(accuracy_table, 'VariableNames', {'Model', 'Class', 'Accuracy'}), 'model_accuracy.xlsx');

    % 7. 画出每一类准确率的折线图
    figure;
    hold on;
    class_names = unique([accuracy_results{1}.per_class_accuracy.keys]);  % 获取所有类别名称
    
    for i = 1:length(model_types)
        model_type = model_types{i};
        per_class_accuracy = accuracy_results{i}.per_class_accuracy;
        
        accuracies = zeros(1, length(class_names));
        for j = 1:length(class_names)
            if isKey(per_class_accuracy, class_names{j})
                accuracies(j) = per_class_accuracy(class_names{j});
            else
                accuracies(j) = NaN;  % 如果某类别没有准确率数据，设为 NaN
            end
        end
        
        % 绘制每个模型对应的准确率折线图
        plot(1:length(class_names), accuracies, '-o', 'DisplayName', model_type, 'LineWidth', 2);
    end
    
    hold off;
    xticks(1:length(class_names));
    xticklabels(class_names);  % 设置 x 轴标签为类别名称
    legend('show');
    title('各模型每类准确率对比');
    xlabel('类别');
    ylabel('准确率 (%)');
    grid on;
    saveas(gcf, 'class_accuracy_comparison.png');  % 保存图表
    disp('准确率折线图保存完成.✅');
    
    disp('分析和结果保存完成.✅');
end
