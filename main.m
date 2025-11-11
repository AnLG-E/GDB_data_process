clc; clear;
%% 读取数据-lhh
% 定义文件夹路径
folderPath = 'F:\GDB\k13';
data = catch_data(folderPath, 1);

%% 数据预处理aa
% 有没有不用data.字段名的方法
% 直接将结构体转换为数组
dataArray = struct2array(data);
% 将结构体的字段名转换为数组
fieldNames = fieldnames(data);

time = dataArray(1,1).vib_data(:,1);
z_data = dataArray(1,1).vib_data(:,3);
 
% 绘制第一个变量的空间图
figure;
plot(time,z_data);
% 用fieldNames来设置标题和轴标签,横轴对了,但是纵轴没有对
% 纵轴是z_data
% 注意一下图窗,从数据的第一个点到最后一个点,图窗大小要适当调整
% 可以用axis函数来调整图窗大小
axis([time(1) time(end) min(z_data) max(z_data)]);
title([strrep(fieldNames{1},'_','\_') '轨道板振动图像']);
xlabel(strrep(fieldNames{1},'_','\_'));
ylabel(strrep('垂向振动数据','_','\_'));

%% 计算RMS值
% 设置窗口参数
window_size = 10000;
% window_type = 'hann';  % 或 'hamming', 'rectangular'
threshold = 0.11002;
% 使用quick_activity_detect函数
[starts, ends, rms] = quick_activity_detect(z_data, window_size, threshold, 25, 50);


% 并将RMS值用折线图表示
figure;
plot(time, rms);
% 用threshold来绘制阈值的水平虚线
line([time(1) time(end)], [threshold threshold], 'Color', 'b', 'LineStyle', '--');
title('垂向振动数据的RMS值');
xlabel(strrep(fieldNames{1},'_','\_'));
ylabel(strrep('RMS值','_','\_'));
axis([time(1) time(end) min(rms) max(rms)]);

% 通过starts和ends来切分z_data
z_data_segments = cell(length(starts), 1);
for i = 1:length(starts)
    z_data_segments{i} = z_data(starts(i):ends(i));
end

% 用结构体存储切分数据
segmentStruct = struct('start', starts, 'end', ends, 'rms', rms, 'data', z_data_segments);

%% 绘制切分后的z_data
% figure;
% for i = 1:length(starts)
%     figure;
%     plot(time(starts(i):ends(i)), z_data_segments{i});
%     title(['活动段 ' num2str(i)]);
%     xlabel(strrep(fieldNames{1},'_','\_'));
%     ylabel(strrep('垂向振动数据','_','\_'));
%     axis([time(starts(i)) time(ends(i)) min(z_data_segments{i}) max(z_data_segments{i})]);
% end
% 将切分的数据绘制到一张图上，使用归一化处理
% 将切分的数据绘制到一张图上，使用归一化处理
figure('Position', [100, 100, 1200, 800]);

% 选择归一化方法
normalization_method = 'zscore'; % 可选: 'zscore', 'minmax', 'none'

% 预计算颜色映射
colors = lines(length(starts)); % 使用lines颜色映射，每个段不同颜色
% 或者使用: colors = jet(length(starts)); % 使用jet颜色映射

% 绘制所有切分段
for i = 1:length(starts)
    % 提取当前段的数据
    current_segment = z_data_segments{i};
    current_time = time(starts(i):ends(i));
    
    % 横坐标归一化 (0到1范围)
    normalizedTime = (current_time - current_time(1)) / (current_time(end) - current_time(1));
    
    % 纵坐标归一化
    switch normalization_method
        case 'zscore'
            % Z-score标准化 (均值=0, 标准差=1)
            normalizedData = (current_segment - mean(current_segment)) / std(current_segment);
            ylabel_text = '标准化幅度 (Z-score)';
            
        case 'minmax'
            % 最大最小归一化 (0到1范围)
            normalizedData = (current_segment - min(current_segment)) / (max(current_segment) - min(current_segment));
            ylabel_text = '归一化幅度 (0-1)';
            
        case 'none'
            % 不进行归一化
            normalizedData = current_segment;
            ylabel_text = '原始幅度';
            
        otherwise
            normalizedData = current_segment;
            ylabel_text = '幅度';
    end
    
    % 绘制当前段，使用不同的颜色
    plot(normalizedTime, normalizedData, 'Color', colors(i,:));
    hold on;
end

% 添加图形修饰
xlabel('归一化时间');
ylabel(ylabel_text);
title(sprintf('%d个切分段的对比 (归一化方法: %s)', length(starts), normalization_method));
grid on;

% 添加图例（如果段数不是太多）
if length(starts) <= 20
    legend_str = arrayfun(@(x) sprintf('段 %d', x), 1:length(starts), 'UniformOutput', false);
    legend(legend_str, 'Location', 'eastoutside');
end

% 设置坐标轴范围
xlim([0, 1]);
%% 计算功率谱与积分

% [f, psd, integral_curve] = compute_psd_integral(z_data, 25000);
% 对每个切分的数据进行计算:
for i = 1:length(segmentStruct)
    % 提取当前切分的数据
    currentData = segmentStruct(i).data;
    
    % 计算功率谱密度和积分曲线
    [f, psd, integral_curve] = compute_psd_integral(currentData, 1000,'nfft',2048*16*16);
    
    % 存储结果
    segmentStruct(i).f = f;
    segmentStruct(i).psd = psd;
    segmentStruct(i).integral_curve = integral_curve;
end 
figure
% 绘制每个切分的功率谱密度和积分曲线
for i = 1:length(segmentStruct)
    % 提取当前切分的结果
    f = segmentStruct(i).f;
    psd = segmentStruct(i).psd;
    integral_curve = segmentStruct(i).integral_curve;
    
    % 绘制功率谱密度
    % figure;
    plot(f, psd);
    title(['切分 ' num2str(i) ' 功率谱密度']);
    xlabel('频率 (Hz)');
    ylabel('功率谱密度');
    hold on;
end

figure
% 绘制每个切分的积分曲线
for i = 1:length(segmentStruct)
    % 提取当前切分的结果
    f = segmentStruct(i).f;
    integral_curve = segmentStruct(i).integral_curve;
    
    % 绘制积分曲线
    % figure;
    plot(f, integral_curve);
    title(['切分 ' num2str(i) ' 积分曲线（累积功率）']);
    xlabel('频率 (Hz)');
    ylabel('归一化累积功率');
    hold on;
end

