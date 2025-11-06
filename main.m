clc; clear;
%% 读取数据
% 定义文件夹路径
folderPath = 'C:\Users\Liluo\Desktop\轨道板数据\data_GDB\k13';
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
window_size = 8000;
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

% 绘制切分后的z_data
figure;
for i = 1:length(starts)
    figure;
    plot(time(starts(i):ends(i)), z_data_segments{i});
    title(['活动段 ' num2str(i)]);
    xlabel(strrep(fieldNames{1},'_','\_'));
    ylabel(strrep('垂向振动数据','_','\_'));
    axis([time(starts(i)) time(ends(i)) min(z_data_segments{i}) max(z_data_segments{i})]);
end