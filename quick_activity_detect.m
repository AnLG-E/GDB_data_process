function [starts, ends, rms_signal] = quick_activity_detect(signal, win_size, threshold, min_gap, min_len)
% 简化修复版本 - 直接重现原代码逻辑但向量化加速

    signal = signal(:)';
    n = length(signal);
    
    % 预分配RMS数组
    rms_signal = zeros(1, n);
    squared_signal = signal.^2;
    half_win = floor(win_size/2);
    
    % 直接重现原代码的RMS计算逻辑，但使用预计算
    for i = 1:n
        start_idx = max(1, i - half_win);
        end_idx = min(n, i + half_win);
        window = squared_signal(start_idx:end_idx);
        rms_signal(i) = sqrt(mean(window));
    end
    
    % 直接重现原代码的活动段检测逻辑，但向量化处理
    active = rms_signal > threshold;
    d_active = diff([false, active, false]);
    starts = find(d_active == 1);
    ends = find(d_active == -1) - 1;
    
    if isempty(starts)
        return;
    end
    
    i = 1;
    while i < length(starts)
        if starts(i+1) - ends(i) < min_gap
            ends(i) = ends(i+1);
            starts(i+1) = [];
            ends(i+1) = [];
        else
            i = i + 1;
        end
    end
    
    valid = (ends - starts) >= min_len;
    starts = starts(valid);
    ends = ends(valid);
    % 这里的starts格式是1xN的向量，每个元素是活动开始的索引
    % 这里的ends格式是1xN的向量，每个元素是活动结束的索引
    % 不是矩阵，是向量
end