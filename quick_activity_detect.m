function [starts, ends, rms] = quick_activity_detect(signal, win_size, threshold, min_gap, min_len)
% 超简洁版本的活动段检测
    % global z_data;
    % signal = z_data';
    % win_size = 5000;
    % threshold = 0.002;
    % min_gap = 25;
    % min_len = 50;
    signal = signal(:)';
    % RMS计算
    rms = sqrt(movmean(signal.^2, win_size));
    
    % 活动检测和边界查找
    active = rms > threshold;
    d_active = diff([false, active, false]);
    starts = find(d_active == 1);
    ends = find(d_active == -1) - 1;
    
    % 合并和过滤（单次循环）
    i = 1;
    % min_gap = 25;
    while i <= length(starts)-1
        if starts(i+1) - ends(i) < min_gap
            ends(i) = ends(i+1);
            starts(i+1) = [];
            ends(i+1) = [];
        else
            i = i + 1;
        end
    end
    
    % 长度过滤
    valid = (ends - starts) >= min_len;
    starts = starts(valid);
    ends = ends(valid);
end