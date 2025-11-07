function [f, psd, integral_curve] = compute_psd_integral(signal, fs, varargin)
% 计算信号的功率谱密度和积分曲线
%
% 输入参数：
%   signal - 输入信号
%   fs - 采样频率
%   varargin - 可选参数：
%       'window' - 窗函数，默认hamming
%       'noverlap' - 重叠点数，默认50%
%       'nfft' - FFT点数，默认nextpow2(length(signal))
%       'freq_range' - 频率范围 [f_min, f_max]，默认[0, fs/2]
%
% 输出参数：
%   f - 频率向量
%   psd - 功率谱密度
%   integral_curve - 积分曲线（累积功率）

    % 参数解析
    p = inputParser;
    addParameter(p, 'window', hamming(round(length(signal)/8)));
    addParameter(p, 'noverlap', []);
    addParameter(p, 'nfft', max(256, 2^nextpow2(length(signal))));
    addParameter(p, 'freq_range', [0, fs/2]);
    parse(p, varargin{:});
    
    % 设置默认重叠（50%）
    if isempty(p.Results.noverlap)
        noverlap = round(length(p.Results.window)/2);
    else
        noverlap = p.Results.noverlap;
    end
    
    % 计算功率谱密度
    [psd, f] = pwelch(signal, p.Results.window, noverlap, p.Results.nfft, fs);
    
    % 转换为dB尺度（可选）
    % psd_db = 10*log10(psd);
    
    % 限制频率范围
    freq_mask = (f >= p.Results.freq_range(1)) & (f <= p.Results.freq_range(2));
    f = f(freq_mask);
    psd = psd(freq_mask);
    
    % 计算积分曲线（累积功率）
    integral_curve = cumtrapz(f, psd);
    
    % 归一化积分曲线（0到1）
    if max(integral_curve) > 0
        integral_curve = integral_curve / max(integral_curve);
    end
end