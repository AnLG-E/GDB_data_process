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

%% 对切分后的加速度数据积分，使其变为位移

% 对切分后的加速度数据积分，使其变为位移
% 假设segmentStruct已经包含切分的加速度数据

% 获取采样频率（需要您根据实际情况设置）
fs = 1000; % 示例采样频率，请根据您的数据修改

% 为每个切分段计算位移
for i = 1:length(segmentStruct)
    % 提取当前段的加速度数据
    acceleration = segmentStruct(i).data;
    
    % 方法1: 双重积分法（加速度 -> 速度 -> 位移）
    displacement = integrate_acceleration_to_displacement(acceleration, fs);
    
    % 方法2: 频域积分法（可选，通常更准确）
    % displacement = frequency_domain_integration(acceleration, fs);
    
    % 将位移数据存储到结构体中
    segmentStruct(i).displacement = displacement;
    
    % 可选：计算位移的统计信息
    segmentStruct(i).displacement_stats = compute_displacement_stats(displacement);
end

% 显示积分结果统计
display_integration_results(segmentStruct);

% 绘制原始加速度和积分后的位移对比
plot_acceleration_vs_displacement(segmentStruct, fs);

% 双重积分函数
function displacement = integrate_acceleration_to_displacement(acceleration, fs)
% 通过双重积分将加速度转换为位移
% 加速度 -> 速度 -> 位移

    dt = 1/fs; % 采样时间间隔
    n = length(acceleration);
    
    % 步骤1: 去除直流分量（消除重力影响和传感器偏移）
    acceleration_detrended = detrend(acceleration);
    
    % 步骤2: 第一次积分 - 加速度到速度
    velocity = cumtrapz(acceleration_detrended) * dt;
    
    % 步骤3: 去除速度的直流分量
    velocity_detrended = detrend(velocity);
    
    % 步骤4: 第二次积分 - 速度到位移
    displacement_raw = cumtrapz(velocity_detrended) * dt;
    
    % 步骤5: 去除位移的线性趋势（补偿积分漂移）
    displacement = detrend(displacement_raw, 'linear');
    
    % 可选：高通滤波去除低频漂移
    % displacement = highpass_filter(displacement, fs, 0.5); % 0.5Hz截止频率
end

% 频域积分函数
function displacement = frequency_domain_integration(acceleration, fs)
% 在频域进行积分，通常更准确

    n = length(acceleration);
    f = (0:n-1) * fs / n;
    
    % FFT变换到频域
    acc_fft = fft(acceleration);
    
    % 频域积分：除以(iω)^2 = -ω^2
    % 注意：避免除以0（直流分量）
    omega = 2 * pi * f;
    omega(1) = omega(2); % 避免除以0
    
    % 频域积分操作
    disp_fft = -acc_fft ./ (omega.^2);
    
    % 返回时域
    displacement_complex = ifft(disp_fft);
    displacement = real(displacement_complex);
    
    % 去除线性趋势
    displacement = detrend(displacement, 'linear');
end

% 高通滤波函数（可选）
function filtered_signal = highpass_filter(signal, fs, cutoff_freq)
% 高通滤波去除低频漂移

    % 设计高通滤波器
    [b, a] = butter(4, cutoff_freq/(fs/2), 'high');
    
    % 应用滤波器
    filtered_signal = filtfilt(b, a, signal);
end

% 位移统计计算函数
function stats = compute_displacement_stats(displacement)
% 计算位移数据的统计信息

    stats.max_displacement = max(displacement);
    stats.min_displacement = min(displacement);
    stats.peak_to_peak = range(displacement);
    stats.rms_displacement = rms(displacement);
    stats.mean_displacement = mean(displacement);
    stats.std_displacement = std(displacement);
end

% 结果显示函数
function display_integration_results(segmentStruct)
% 显示积分结果的统计信息

    fprintf('=== 加速度积分到位移结果统计 ===\n\n');
    fprintf('总段数: %d\n', length(segmentStruct));
    fprintf('\n');
    
    max_disp = zeros(length(segmentStruct), 1);
    min_disp = zeros(length(segmentStruct), 1);
    peak_to_peak = zeros(length(segmentStruct), 1);
    
    for i = 1:length(segmentStruct)
        if isfield(segmentStruct(i), 'displacement_stats')
            stats = segmentStruct(i).displacement_stats;
            max_disp(i) = stats.max_displacement;
            min_disp(i) = stats.min_displacement;
            peak_to_peak(i) = stats.peak_to_peak;
            
            fprintf('段 %d: 最大位移=%.6f, 最小位移=%.6f, 峰峰值=%.6f, RMS=%.6f\n', ...
                i, stats.max_displacement, stats.min_displacement, ...
                stats.peak_to_peak, stats.rms_displacement);
        end
    end
    
    fprintf('\n总体统计:\n');
    fprintf('平均最大位移: %.6f ± %.6f\n', mean(max_disp), std(max_disp));
    fprintf('平均最小位移: %.6f ± %.6f\n', mean(min_disp), std(min_disp));
    fprintf('平均峰峰值: %.6f ± %.6f\n', mean(peak_to_peak), std(peak_to_peak));
end

% 对比绘图函数
function plot_acceleration_vs_displacement(segmentStruct, fs)
% 绘制加速度和位移的对比图

    % 选择几个代表性的段进行显示
    if length(segmentStruct) > 6
        display_segments = [1, 2, 3, length(segmentStruct)-2, length(segmentStruct)-1, length(segmentStruct)];
    else
        display_segments = 1:length(segmentStruct);
    end
    
    figure('Position', [100, 100, 1400, 1000]);
    
    for i = 1:length(display_segments)
        seg_idx = display_segments(i);
        
        % 创建时间向量
        t_acc = (0:length(segmentStruct(seg_idx).data)-1) / fs;
        t_disp = (0:length(segmentStruct(seg_idx).displacement)-1) / fs;
        
        % 子图1: 加速度
        subplot(length(display_segments), 2, 2*i-1);
        plot(t_acc, segmentStruct(seg_idx).data, 'b', 'LineWidth', 1.5);
        title(sprintf('段 %d - 加速度', seg_idx));
        xlabel('时间 (s)');
        ylabel('加速度');
        grid on;
        
        % 子图2: 位移
        subplot(length(display_segments), 2, 2*i);
        plot(t_disp, segmentStruct(seg_idx).displacement, 'r', 'LineWidth', 1.5);
        title(sprintf('段 %d - 位移', seg_idx));
        xlabel('时间 (s)');
        ylabel('位移');
        grid on;
    end
    
    sgtitle('加速度与位移对比');
end

% 所有段的位移对比图
function plot_all_displacements(segmentStruct, fs)
% 绘制所有段的位移对比图

    figure('Position', [100, 100, 1200, 800]);
    
    colors = jet(length(segmentStruct));
    
    for i = 1:length(segmentStruct)
        % 归一化时间 (0到1)
        t_norm = (0:length(segmentStruct(i).displacement)-1) / length(segmentStruct(i).displacement);
        
        % 归一化位移（便于比较形状）
        displacement_norm = segmentStruct(i).displacement / max(abs(segmentStruct(i).displacement));
        
        plot(t_norm, displacement_norm, 'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;
    end
    
    xlabel('归一化时间');
    ylabel('归一化位移');
    title('所有切分段的位移对比');
    grid on;
    
    % 添加颜色条指示段索引
    colormap(jet);
    c = colorbar;
    c.Label.String = '段索引';
    c.Ticks = linspace(0, 1, min(10, length(segmentStruct)));
    c.TickLabels = round(linspace(1, length(segmentStruct), length(c.Ticks)));
end

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

