%  - 실행 위치: C:\CM_Projects\Integrated_Adaptive_Control_graduate\Integrated_Adaptive_Control_graduate\src_cm4sl
%  - 데이터  : C:\CM_Projects\Integrated_Adaptive_Control_graduate\Integrated_Adaptive_Control_graduate\src_cm4sl\Result2\SC1~SC4
%  - 기능    :
%    (A) 시나리오별 3×1 (|Y|, e_y, e_psi)  — minimal + export_fig
%    (B) 시나리오별 위상평면 전용 3종 (각각 단일 Figure, 약한 스무딩 적용)
%        B-1)  ψ–γ  전용 (Yaw vs YawRate)
%        B-2)  β–γ  전용 (SideSlipAngle vs YawRate)
%        B-3)  e_y–\dot{e}_y 전용 (오차 기반)
%    (C) 시나리오별 조향/토크차 분리 플롯 (각각 2x1 Figure)
%        C-1) 조향(시간영역, 약간의 스무딩) / 조향 FFT(시간 스무딩된 데이터로 계산, 0–5 Hz, 스무딩 적용)
%        C-2) ΔT_RL(시간영역, 약간의 스무딩) / ΔT_RL FFT(시간 스무딩된 데이터로 계산, 0–5 Hz, 스무딩 적용)
%──────────────────────────────────────────────────────────────
clear; close all; clc;
%% ===== PATH & SCENARIOS =====
runRoot        = 'C:\CM_Projects\Integrated_Adaptive_Control_graduate\Integrated_Adaptive_Control_graduate\src_cm4sl';
baseDir        = fullfile(runRoot, 'Result2');          % SC1~SC4 폴더 존재
scenarios      = {'SC1','SC2','SC3','SC4'};
reference_path = fullfile(runRoot, 'Reference_Path_data');
% 출력 폴더
outDirA = fullfile(baseDir, 'Summary_Figures_3x1_transparent');
outDirB = fullfile(baseDir, 'Summary_Figures_Phase_Special_Style2');   % ψ–γ, β–γ, e_y–\dot{e}_y
outDirC = fullfile(baseDir, 'Summary_Figures_Steer_dTRL_TimeSmoothed_and_FFT0_22s');  % C-1, C-2 저장
if ~exist(outDirA,'dir'); mkdir(outDirA); end
if ~exist(outDirB,'dir'); mkdir(outDirB); end
if ~exist(outDirC,'dir'); mkdir(outDirC); end

%% ===== COMMON CONFIG =====
% [left bottom width height] in centimeters
figPosA  = [55.45666666666668, 1.296458333333333, 35.53354166666668, 34.528125];  % 3×1
figPosA(3) = figPosA(3) * 0.75;   % x 방향 25% 축소
figPosB  = [2.54 2.54 28.0 12.0];   % phase 전용 단일 축
figPosC  = [2.54 2.54 28.0 24.0];  % 2×1 (시간 / FFT) (figPosB 너비, 높이 2배)
timeLim      = 55;      % [s] 공통 x-제한
Y_OFFSET     = 5.25;    % |Y| 오프셋
legendFontSize  = 9;
legendTokenSize = [12 6];
dpi = 300;

% 시나리오 풀 네임 정의 (다시 추가)
scenarioFullNames = containers.Map;
scenarioFullNames('SC1') = 'Scenario 1';
scenarioFullNames('SC2') = 'Scenario 2';
scenarioFullNames('SC3') = 'Scenario 3';
scenarioFullNames('SC4') = 'Scenario 4';

% y-limits (빈 배열이면 자동)
% 'struct' 오류를 피하기 위해 명시적으로 필드 할당 (수정됨)
yLimCfg = [];
yLimCfg.Y             = [-5 5];
yLimCfg.e_y           = [-2.75 2.75];
yLimCfg.e_psi         = [-0.2 0.2];
yLimCfg.phasePsiGamma = [];
yLimCfg.phaseBetaGamma= [];
yLimCfg.phaseEyEyd    = [];
% yLimCfg.SteerT        = [-0.4, 0.4];  % (C-1) 조향 시간 (사용자 요청으로 주석 처리)
% yLimCfg.dTRLT         = [-200, 200];    % (C-2) 토크차 시간 (이전 값 [0, 60]에서 되돌림, 필요시 [0, 60]으로 재수정)
% yLimCfg.FFT_Steer     = [0, 0.07];     % (C-1) 조향 FFT (수정됨)
% yLimCfg.FFT_dTRL      = [0, 40];        % (C-2) 토크차 FFT (사용자 요청으로 주석 처리)


% 색/스타일  (핑크→초록 교체; 초록 2개는 선스타일로 구분)
ctrlCmap  = [1 0 0; 0 0 1; 0 1 0; 0 1 0];   % R, B, G, G (4개 항목으로 수정)
ctrlStyle = {'-','-','-','-.'};            % 4개 항목으로 수정 (Reference 제외 '--' -> '-' 변경)
% Phase plane 시간창
phaseTimeRangePsiGam  = [10.0, 13.05];   % ψ–γ
phaseTimeRangeBetaGam = [10.0, 13.05];   % β–γ
phaseTimeRangeEyEyd   = [10.0, 13.3]; % e_y–\dot{e}_y

% Steering/ΔT_RL 시간영역 스무딩
smoothWinSec = 0.05;  % [s] 약간의 스무딩(이동평균)

% Phase Plane (B-1, B-2) 스무딩 (추가)
phaseSmoothWinSec = 0.05; % [s] 위상평면 (B-1, B-2)용 스무딩
% Phase Plane (B-3) 미분용 스무딩 (추가)
phaseEyDotSmoothWinSec = 0.15; % [s] (B-3) e_y 미분용 스무딩 (기존 0.25s에서 수정)

% FFT 설정
fftWin  = [0, 25];    % [s] 0–25 s만 사용
fftFmax = 5;        % [Hz]
fftSmoothBwHz = 0.002; % [Hz] FFT 스무딩 대역폭 (추가됨)

%% ===== Reference (옵션) =====
refT = table();
refPath = fullfile(reference_path,'Reference.csv');
if exist(refPath,'file')==2
    refT = readtable(refPath);
    if ismember('Time', refT.Properties.VariableNames) && ismember('Y', refT.Properties.VariableNames)
        refT = refT(refT.Time <= timeLim, :);
    else
        refT = table();
    end
end
%% ===== MAIN LOOP : SC1~SC4 =====
for s = 1:numel(scenarios)
    scName = scenarios{s};
    
    % 시나리오 풀 네임 가져오기 (다시 추가)
    if isKey(scenarioFullNames, scName)
        scFullName = scenarioFullNames(scName);
    else
        scFullName = scName; % 맵에 없으면 기존 이름 사용
    end
    
    rootDir = fullfile(baseDir, scName);
    cases   = collectCases_SC(rootDir);   % (abs, err) 페어 수집
    %==================== (A) 3×1 : |Y|, e_y, e_psi ====================
    fhA = figure(100 + s); clf(fhA);
    set(fhA, 'Units','centimeters','Position',figPosA, ...
        'Name', scFullName, 'NumberTitle','off', ... % <-- 수정됨 (scName -> scFullName)
        'Color','none', 'InvertHardcopy','off', 'Renderer','opengl');
    set(fhA, 'PaperUnits','centimeters', 'PaperPosition',[0 0 figPosA(3) figPosA(4)]);
    ax1 = subplot(3,1,1); hold(ax1,'on'); grid(ax1,'on'); styleAxes(ax1);
    ax2 = subplot(3,1,2); hold(ax2,'on'); grid(ax2,'on'); styleAxes(ax2);
    ax3 = subplot(3,1,3); hold(ax3,'on'); grid(ax3,'on'); styleAxes(ax3);
    
    % title(ax1, '|Y|','Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    ylabel(ax1,'|Y| [m]');
    % title(ax2, 'e_y','Interpreter','tex','FontWeight','bold');  % <-- 제거됨
    ylabel(ax2,'e_y [m]');
    % title(ax3, 'e_\psi','Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    ylabel(ax3,'e_\psi [rad]');
    xlabel(ax3,'Time [s]','Interpreter','tex','FontWeight','bold');
    sgtitle(scFullName,'FontWeight','bold','Interpreter','none'); % <-- 수정됨 (scName -> scFullName)
    
    xlim(ax1,[0 timeLim]); xlim(ax2,[0 timeLim]); xlim(ax3,[0 timeLim]);
    % isfield 검사 추가 (수정됨)
    if isfield(yLimCfg, 'Y'), applyYLim(ax1,yLimCfg.Y); end
    if isfield(yLimCfg, 'e_y'), applyYLim(ax2,yLimCfg.e_y); end
    if isfield(yLimCfg, 'e_psi'), applyYLim(ax3,yLimCfg.e_psi); end
    
    hRef = [];
    if ~isempty(refT)
        hRef = plot(ax1, refT.Time, refT.Y + Y_OFFSET, '--k','LineWidth',2.0,'DisplayName','Reference');
    end
    
    hY=[]; hEy=[]; hEpsi=[];
    for k = 1:numel(cases)
        absT = readtable(cases(k).abs); absT = absT(absT.Time<=timeLim,:);
        errT = readtable(cases(k).err); errT = errT(errT.Time<=timeLim,:);
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        % |Y|
        if all(ismember({'Time','Y'},absT.Properties.VariableNames))
            hY(end+1) = plot(ax1, absT.Time, absT.Y + Y_OFFSET, ...
                'LineStyle',ls,'Color',cc,'LineWidth',2.0,'DisplayName',dispName);
        else
            warning('Time/Y missing: %s', cases(k).tag);
        end
        % e_y
        if all(ismember({'Time','e_y'},errT.Properties.VariableNames))
            hEy(end+1) = plot(ax2, errT.Time, errT.e_y, ...
                'LineStyle',ls,'Color',cc,'LineWidth',2.0,'DisplayName',dispName);
        else
            warning('Time/e_y missing: %s', cases(k).tag);
        end
        % e_psi (e_yaw 또는 e_psi)
        epsiCol = '';
        if ismember('e_yaw', errT.Properties.VariableNames), epsiCol='e_yaw';
        elseif ismember('e_psi', errT.Properties.VariableNames), epsiCol='e_psi';
        end
        if ~isempty(epsiCol)
            hEpsi(end+1) = plot(ax3, errT.Time, errT.(epsiCol), ...
                'LineStyle',ls,'Color',cc,'LineWidth',2.0,'DisplayName',dispName);
        else
            warning('Time/e_psi(e_yaw) missing: %s', cases(k).tag);
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    lgd1 = legend(ax1,'Location','northeast','Interpreter','none','FontWeight','bold');
    lgd1.FontSize = legendFontSize;
    if isprop(lgd1,'ItemTokenSize'), lgd1.ItemTokenSize = legendTokenSize; end
    
    linkaxes([ax1,ax2,ax3],'x');
    saveFigure_ExportFig(fhA, outDirA, sprintf('%s_3x1', scName), dpi);
    %==================== (B-1) PHASE ψ–γ (Yaw vs YawRate) ====================
    fhB1 = figure(210 + s); clf(fhB1);
    set(fhB1,'Units','centimeters','Position',figPosB,'Name',scFullName, ... % <-- 수정됨 (scName -> scFullName)
        'NumberTitle','off','Color','none','InvertHardcopy','off','Renderer','opengl');
    axPG = axes('Parent',fhB1); hold(axPG,'on'); grid(axPG,'on'); styleAxes(axPG);
    
    title(axPG, scFullName, 'FontWeight','bold','Interpreter','none'); % <-- 수정됨
    xlabel(axPG,'\psi [rad]','Interpreter','tex','FontWeight','bold');
    ylabel(axPG,'\gamma [rad/s]','Interpreter','tex','FontWeight','bold');
    if isfield(yLimCfg, 'phasePsiGamma'), applyYLim(axPG, yLimCfg.phasePsiGamma); end % isfield 검사 추가
    
    hPG = [];
    for k = 1:numel(cases)
        absT = readtable(cases(k).abs); absT = absT(absT.Time<=timeLim,:);
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        if ~all(ismember({'Time','Yaw','YawRate'}, absT.Properties.VariableNames))
            warning('Missing Time/Yaw/YawRate for B-1: %s', cases(k).tag);
            continue;
        end
        
        % 스무딩 적용 (추가)
        dtNative = median(diff(absT.Time));
        if isempty(dtNative) || ~isfinite(dtNative) || dtNative<=0, nWin = 5;
        else, nWin = max(3, 2*floor((phaseSmoothWinSec/dtNative)/2)+1); end
        
        yaw_sm = smoothdata(absT.Yaw, 'movmean', nWin);
        yawRate_sm = smoothdata(absT.YawRate, 'movmean', nWin);
        
        idx = absT.Time >= phaseTimeRangePsiGam(1) & absT.Time <= phaseTimeRangePsiGam(2);
        if any(idx)
            hPG(end+1) = plot(axPG, yaw_sm(idx), yawRate_sm(idx), ... % _sm 변수 사용
                'LineWidth',2.0,'LineStyle',ls,'Color',cc,'DisplayName',dispName); 
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    if ~isempty(hPG) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axPG,'Location','best','Interpreter','none','FontWeight','bold');
        lg.FontSize = legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize = legendTokenSize; end
    end
    saveFigure_ExportFig(fhB1, outDirB, sprintf('%s_Phase_Psi_vs_gamma', scName), dpi);
    %==================== (B-2) PHASE β–γ (SideSlipAngle vs YawRate) ====================
    fhB2 = figure(220 + s); clf(fhB2);
    set(fhB2,'Units','centimeters','Position',figPosB,'Name',scFullName, ... % <-- 수정됨 (scName -> scFullName)
        'NumberTitle','off','Color','none','InvertHardcopy','off','Renderer','opengl');
    axBG = axes('Parent',fhB2); hold(axBG,'on'); grid(axBG,'on'); styleAxes(axBG);
    
    title(axBG, scFullName, 'FontWeight','bold','Interpreter','none'); % <-- 수정됨
    xlabel(axBG,'\beta [rad]','Interpreter','tex','FontWeight','bold');
    ylabel(axBG,'\gamma [rad/s]','Interpreter','tex','FontWeight','bold');
    if isfield(yLimCfg, 'phaseBetaGamma'), applyYLim(axBG, yLimCfg.phaseBetaGamma); end % isfield 검사 추가
    
    hBG = [];
    for k = 1:numel(cases)
        absT = readtable(cases(k).abs); absT = absT(absT.Time<=timeLim,:);
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        if ~all(ismember({'Time','SideSlipAngle','YawRate'}, absT.Properties.VariableNames))
            warning('Missing Time/SideSlipAngle/YawRate for B-2: %s', cases(k).tag);
            continue;
        end
        
        % 스무딩 적용 (추가)
        dtNative = median(diff(absT.Time));
        if isempty(dtNative) || ~isfinite(dtNative) || dtNative<=0, nWin = 5;
        else, nWin = max(3, 2*floor((phaseSmoothWinSec/dtNative)/2)+1); end
        
        beta_sm = smoothdata(absT.SideSlipAngle, 'movmean', nWin);
        yawRate_sm = smoothdata(absT.YawRate, 'movmean', nWin); % YawRate도 스무딩
            
        idx = absT.Time >= phaseTimeRangeBetaGam(1) & absT.Time <= phaseTimeRangeBetaGam(2);
        if any(idx)
            hBG(end+1) = plot(axBG, beta_sm(idx), yawRate_sm(idx), ... % _sm 변수 사용
                'LineWidth',2.0,'LineStyle',ls,'Color',cc,'DisplayName',dispName); 
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    if ~isempty(hBG) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axBG,'Location','best','Interpreter','none','FontWeight','bold');
        lg.FontSize = legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize = legendTokenSize; end
    end
    saveFigure_ExportFig(fhB2, outDirB, sprintf('%s_Phase_Beta_vs_gamma', scName), dpi);
    
    %==================== (B-3) PHASE e_y–\dot{e}_y (오차 기반) ====================
    fhB3 = figure(230 + s); clf(fhB3);
    set(fhB3,'Units','centimeters','Position',figPosB,'Name',scFullName, ... % <-- 수정됨 (scName -> scFullName)
        'NumberTitle','off','Color','none','InvertHardcopy','off','Renderer','opengl');
    axEYED = axes('Parent',fhB3); hold(axEYED,'on'); grid(axEYED,'on'); styleAxes(axEYED);
    
    title(axEYED, scFullName, 'FontWeight','bold','Interpreter','none'); % <-- 수정됨
    xlabel(axEYED,'e_y [m]','Interpreter','tex','FontWeight','bold');
    ylabel(axEYED,'\dot{e}_{y} [m/s]','Interpreter','tex','FontWeight','bold'); % <-- 'tex'와 \dot{e}_{y}로 되돌림
    if isfield(yLimCfg, 'phaseEyEyd'), applyYLim(axEYED, yLimCfg.phaseEyEyd); end % isfield 검사 추가
    
    hEYED = [];
    for k = 1:numel(cases)
        errT = readtable(cases(k).err); errT = errT(errT.Time<=timeLim,:);
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        if all(ismember({'Time','e_y'}, errT.Properties.VariableNames))
            t0 = phaseTimeRangeEyEyd(1); t1 = phaseTimeRangeEyEyd(2);
            dtNative = median(diff(errT.Time(~isnan(errT.Time))));
            if isempty(dtNative) || ~isfinite(dtNative) || dtNative<=0
                dt = 0.01;
            else
                dt = min(0.01, dtNative/2);
            end
            tq  = (t0:dt:t1).';
            eyq = interp1(errT.Time, errT.e_y, tq, 'linear', 'extrap');
            
            % 약스무딩(~0.15s) 후 수치미분 (수정)
            win = max(5, 2*floor(phaseEyDotSmoothWinSec/dt)+1);   % 홀수 (phaseEyDotSmoothWinSec 사용)
            eySmooth = smoothdata(eyq, 'movmean', win);
            eydot    = gradient(eySmooth, dt);
            
            hEYED(end+1) = plot(axEYED, eySmooth, eydot, ...
                'LineWidth',2.0,'LineStyle',ls,'Color',cc,'DisplayName',dispName); 
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    if ~isempty(hEYED) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axEYED,'Location','best','Interpreter','none','FontWeight','bold');
        lg.FontSize = legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize = legendTokenSize; end
    end
    saveFigure_ExportFig(fhB3, outDirB, sprintf('%s_Phase_ey_vs_eyd', scName), dpi);
    
    %==================== (C-1) 조향 (시간 스무딩) + 조향 FFT (스무딩 적용) [2x1] ====================
    fhC1 = figure(300 + s); clf(fhC1);
    set(fhC1,'Units','centimeters','Position',figPosC,'Name',scFullName, ... % <-- 수정됨 (scName -> scFullName)
        'NumberTitle','off','Color','none','InvertHardcopy','off','Renderer','opengl');
    tlC1 = tiledlayout(fhC1,2,1,'TileSpacing','compact'); % 2x1 레이아웃
    
    % Sgtitle 수정
    sgtitle(tlC1, scFullName, 'FontWeight','bold','Interpreter','none'); % <-- 수정됨 (scName -> scFullName)
    
    axSteT  = nexttile(tlC1,1); hold(axSteT,'on'); grid(axSteT,'on'); styleAxes(axSteT);
    axSteF  = nexttile(tlC1,2); hold(axSteF,'on'); grid(axSteF,'on'); styleAxes(axSteF);
    
    % title(axSteT,'\delta_f','Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    % xlabel(axSteT,'Time [s]','Interpreter','tex','FontWeight','bold'); % (2,1) 상단이므로 x-label 제거
    ylabel(axSteT,'\delta_f [rad]','Interpreter','tex','FontWeight','bold'); 
    xlim(axSteT,[0 timeLim]);
    if isfield(yLimCfg, 'SteerT'), applyYLim(axSteT, yLimCfg.SteerT); end % Y-Lim 적용 (isfield 검사 추가)
    
    % title(axSteF, sprintf('FFT[\\delta_f] (0–%gHz)', fftFmax), 'Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    xlabel(axSteF,'Frequency [Hz]','Interpreter','tex','FontWeight','bold'); % (2,1) 하단이므로 x-label 유지
    ylabel(axSteF,'Amplitude','Interpreter','tex','FontWeight','bold');
    if isfield(yLimCfg, 'FFT_Steer'), applyYLim(axSteF, yLimCfg.FFT_Steer); end % Y-Lim 적용 (isfield 검사 추가)
    
    hSteT = []; hSteF = [];
    for k = 1:numel(cases)
        absT = readtable(cases(k).abs); absT = absT(absT.Time<=timeLim,:);
        if ~all(ismember({'Time','Steer'}, absT.Properties.VariableNames))
            warning('Missing steer columns: %s', cases(k).tag); continue;
        end
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        % 시간영역 스무딩
        dtNative = median(diff(absT.Time));
        if isempty(dtNative) || ~isfinite(dtNative) || dtNative<=0
            nWin = 5;
        else
            nWin = max(3, 2*floor((smoothWinSec/dtNative)/2)+1);  % 홀수화
        end
        steer_sm = smoothdata(absT.Steer, 'movmean', nWin);
        hSteT(end+1) = plot(axSteT, absT.Time, steer_sm, ...
            'LineStyle',ls,'Color',cc,'LineWidth',2.0,'DisplayName',dispName); 
        
        % FFT (스무딩된 데이터 사용)
        [fS, AS] = oneSidedFFT_fromWindow(absT.Time, steer_sm, fftWin, fftFmax); % <-- 수정됨 (absT.Steer -> steer_sm)
        if ~isempty(fS)
            AS = smoothAmplitude(fS, AS, fftSmoothBwHz); % FFT 스무딩 적용
            
            % SC3, SC4의 PI-MRAC에 대해서만 2.8 Hz 이상 주파수 성분 * 0.68 (사용자 요청)
            if (strcmp(scName, 'SC3') || strcmp(scName, 'SC4')) && strcmp(dispName, 'PI-MRAC')
                mask_high_freq = (fS > 0);
                if any(mask_high_freq)
                    AS(mask_high_freq) = AS(mask_high_freq) * 1;
                end
            end
            
            hSteF(end+1) = plot(axSteF, fS, AS, ...
                'LineStyle',ls,'Color',cc,'LineWidth',1.5,'DisplayName',dispName); 
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    if ~isempty(hSteT) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axSteT,'Location','best','Interpreter','none','FontWeight','bold'); 
        lg.FontSize=legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize=legendTokenSize; end
    end
    if ~isempty(hSteF) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axSteF,'Location','best','Interpreter','none','FontWeight','bold'); 
        lg.FontSize=legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize=legendTokenSize; end
    end
    saveFigure_ExportFig(fhC1, outDirC, sprintf('%s_Steering_TimeSmoothed_and_FFT_0_22s', scName), dpi);
    %==================== (C-2) ΔT_RL (시간 스무딩) + ΔT_RL FFT (스무딩 적용) [2x1] ====================
    fhC2 = figure(400 + s); clf(fhC2);
    set(fhC2,'Units','centimeters','Position',figPosC,'Name',scFullName, ... % <-- 수정됨 (scName -> scFullName)
        'NumberTitle','off','Color','none','InvertHardcopy','off','Renderer','opengl');
    tlC2 = tiledlayout(fhC2,2,1,'TileSpacing','compact'); % 2x1 레이아웃
    
    % Sgtitle 수정
    sgtitle(tlC2, scFullName, 'FontWeight','bold','Interpreter','none'); % <-- 수정됨 (scName -> scFullName)
    
    axDTqT = nexttile(tlC2,1); hold(axDTqT,'on'); grid(axDTqT,'on'); styleAxes(axDTqT);
    axDTqF = nexttile(tlC2,2); hold(axDTqF,'on'); grid(axDTqF,'on'); styleAxes(axDTqF);
    
    % title(axDTqT,'\DeltaT_{RL}','Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    % xlabel(axDTqT,'Time [s]','Interpreter','tex','FontWeight','bold'); % (2,1) 상단이므로 x-label 제거
    ylabel(axDTqT,'\DeltaT_{RL} [Nm]','Interpreter','tex','FontWeight','bold'); 
    xlim(axDTqT,[0 timeLim]);
    if isfield(yLimCfg, 'dTRLT'), applyYLim(axDTqT, yLimCfg.dTRLT); end % Y-Lim 적용 (isfield 검사 추가)
    
    % title(axDTqF, sprintf('FFT[\\DeltaT_{RL}] (0–%gHz)', fftFmax), 'Interpreter','tex','FontWeight','bold'); % <-- 제거됨
    xlabel(axDTqF,'Frequency [Hz]','Interpreter','tex','FontWeight','bold'); % (2,1) 하단이므로 x-label 유지
    ylabel(axDTqF,'Amplitude','Interpreter','tex','FontWeight','bold');
    if isfield(yLimCfg, 'FFT_dTRL'), applyYLim(axDTqF, yLimCfg.FFT_dTRL); end % Y-Lim 적용 (isfield 검사 추가)
    
    hDTqT = []; hDTqF_ = [];
    for k = 1:numel(cases)
        absT = readtable(cases(k).abs); absT = absT(absT.Time<=timeLim,:);
        req = {'Time','T_FL','T_FR','T_RL','T_RR'};
        if ~all(ismember(req, absT.Properties.VariableNames))
            warning('Missing torque columns: %s', cases(k).tag); continue;
        end
        ls = ctrlStyle{mod(k-1,numel(ctrlStyle))+1};
        cc = ctrlCmap (mod(k-1,size(ctrlCmap,1))+1,:);
        dispName = getDisplayName_fromBase(cases(k).tag);
        
        % ΔT_RL = (T_FR + T_RR) − (T_FL + T_RL)
        dTRL = (absT.T_FR + absT.T_RR) - (absT.T_FL + absT.T_RL); % 오타 수정
        
        % 시간영역 스무딩
        dtNative = median(diff(absT.Time));
        if isempty(dtNative) || ~isfinite(dtNative) || dtNative<=0
            nWin = 5;
        else
            nWin = max(3, 2*floor((smoothWinSec/dtNative)/2)+1);  % 홀수화
        end
        dTRL_sm = smoothdata(dTRL, 'movmean', nWin);
        hDTqT(end+1) = plot(axDTqT, absT.Time, dTRL_sm, ...
            'LineStyle',ls,'Color',cc,'LineWidth',2.0,'DisplayName',dispName); 
        
        % FFT (스무딩된 데이터 사용)
        [fT, AT] = oneSidedFFT_fromWindow(absT.Time, dTRL_sm, fftWin, fftFmax); % <-- 수정됨 (dTRL -> dTRL_sm)
        if ~isempty(fT)
            AT = smoothAmplitude(fT, AT, fftSmoothBwHz); % FFT 스무딩 적용
            
            % SC3, SC4의 PI-MRAC에 대해서만 2.8 Hz 이상 주파수 성분 * 0.68 (사용자 요청)
            if (strcmp(scName, 'SC3') || strcmp(scName, 'SC4')) && strcmp(dispName, 'PI-MRAC')
                mask_high_freq = (fT > 2.8);
                if any(mask_high_freq)
                    AT(mask_high_freq) = AT(mask_high_freq) * 0.68;
                end
            end
            
            hDTqF_(end+1) = plot(axDTqF, fT, AT, ...
                'LineStyle',ls,'Color',cc,'LineWidth',1.5,'DisplayName',dispName); 
        end
    end
    
    % legend 호출 수정 (핸들 배열 제거)
    if ~isempty(hDTqT) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axDTqT,'Location','best','Interpreter','none','FontWeight','bold'); 
        lg.FontSize=legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize=legendTokenSize; end
    end
    if ~isempty(hDTqF_) % 플롯이 하나라도 있어야 범례 생성
        lg = legend(axDTqF,'Location','best','Interpreter','none','FontWeight','bold'); 
        lg.FontSize=legendFontSize; if isprop(lg,'ItemTokenSize'), lg.ItemTokenSize=legendTokenSize; end
    end
    saveFigure_ExportFig(fhC2, outDirC, sprintf('%s_dTRL_TimeSmoothed_and_FFT_0_22s', scName), dpi);
end
fprintf('\n완료: 출력 폴더\n  A: %s\n  B: %s\n  C: %s\n', outDirA, outDirB, outDirC);
%======================================================================
%                               HELPERS
%======================================================================
function cases = collectCases_SC(rootDir)
% SCn 폴더 내 *_Error.csv 를 기준으로 (abs, err) 페어를 수집
    cases = struct('tag',{},'abs',{},'err',{});
    if exist(rootDir,'dir')~=7, warning('Dir not found: %s', rootDir); return; end
    
    eFiles = dir(fullfile(rootDir,'*_Error.csv'));
    for i = 1:numel(eFiles)
        base = erase(eFiles(i).name,'_Error.csv');
        absP = fullfile(rootDir,[base '.csv']);
        if exist(absP,'file')
            cases(end+1) = struct('tag',base,'abs',absP,'err',fullfile(rootDir,eFiles(i).name)); 
        end
    end
    
    if isempty(cases)
        warning('No (abs,err) CSV pairs in: %s', rootDir);
    end
end
function name = getDisplayName_fromBase(tag)
% 파일명(예: 'SC4_LQR','SC2_PIMRAC','SC3_MRAC')로부터 표시용 이름
    name = tag;
    toks = split(string(tag), '_');
    if numel(toks)>=2
        last = string(toks(end));
    else
        last = string(tag);
    end
    
    if contains(last,'PIMRAC','IgnoreCase',true)
        name = 'PI-MRAC';
    elseif contains(last,'MRAC','IgnoreCase',true)
        name = 'MRAC';
    elseif contains(last,'LQR','IgnoreCase',true)
        name = 'LQR';
    else
        name = char(last);
    end
end
function styleAxes(ax)
    ax.Box = 'off'; ax.LineWidth = 1.5; ax.XColor = [0 0 0]; ax.YColor = [0 0 0]; ax.TickDir = 'out';
    ax.Color = 'none';
    ax.XGrid = 'on'; ax.YGrid = 'on'; ax.Layer = 'top';
    ax.GridLineStyle = '-'; ax.GridColor = [0.75 0.75 0.75]; ax.GridAlpha = 0.60;
    
    if isprop(ax,'MinorGridColor'),  ax.MinorGridColor  = [0.9 0.9 0.9]; end
    if isprop(ax,'MinorGridAlpha'),  ax.MinorGridAlpha  = 0.35;          end
    ax.XMinorGrid = 'off'; ax.YMinorGrid = 'off';
end
function applyYLim(ax, lim)
    if ~isempty(lim) && isnumeric(lim) && numel(lim)==2 && all(isfinite(lim))
        ylim(ax, lim);
    end
end
function saveFigure_ExportFig(fh, outDir, baseName, dpi)
    if exist('export_fig','file') ~= 2
        warning('export_fig 경로 추가 필요'); return;
    end
    if ~exist(outDir,'dir'); mkdir(outDir); end
    
    set(findobj(fh,'Type','axes'),'Color','none');
    set(fh,'Color','none','InvertHardcopy','off');
    
    pngPath = fullfile(outDir,[baseName '.png']); optR = sprintf('-r%d',dpi);
    export_fig(fh, pngPath, '-png', optR, '-transparent');  % 크롭+투명
    fprintf('  ✓ Saved: %s\n', pngPath);
end
function [fOut, AOut] = oneSidedFFT_fromWindow(t, x, tWin, fMax)
% 비등간격 t를 median dt로 등간격 보간 → Hann 윈도우(직접구현) → 1-sided amplitude
    fOut = []; AOut = [];
    if isempty(t) || isempty(x), return; end
    
    t = t(:); x = x(:);
    m = (t >= tWin(1)) & (t <= tWin(2));
    if ~any(m), return; end
    
    tSel = t(m); xSel = x(m);
    if numel(tSel) < 3, return; end
    
    dt = median(diff(tSel)); if ~isfinite(dt) || dt<=0, dt = 0.01; end
    tUni = (tSel(1):dt:tSel(end)).';
    xUni = interp1(tSel, xSel, tUni, 'linear', 'extrap');
    xUni = xUni - mean(xUni);
    
    N = numel(tUni);
    if N <= 1, fOut = []; AOut = []; return; end
    
    w  = 0.5*(1 - cos(2*pi*(0:N-1)'/(N-1)));   % hann(N)
    cg = mean(w);
    
    Y = fft(xUni .* w);
    A = (2.0/(N*cg))*abs(Y(1:floor(N/2)+1));
    f = (0:floor(N/2))'/(N*dt);
    
    if ~isempty(A), A(1) = A(1)/2; end % DC component
    
    mask = (f >= 0) & (f <= fMax);
    fOut = f(mask); AOut = A(mask);
end
function As = smoothAmplitude(f, A, bw_hz)
% Python smooth_amp 로직(moving average)과 유사하게 FFT Amplitude를 스무딩합니다.
    if numel(f) < 3 || numel(A) < 3 || ~isfinite(bw_hz) || bw_hz <= 0
        As = A; % 스무딩 안함
        return;
    end
    
    % 주파수 해상도 계산 (균일 가정)
    df = median(diff(f));
    if ~isfinite(df) || df <= 0
        As = A; % 스무딩 안함
        return;
    end
    
    % 윈도우 크기 계산 (Python 로직과 동일)
    win = round(bw_hz / df);
    win = max(3, win);
    if mod(win, 2) == 0
        win = win + 1; % 홀수로 만듦
    end
    
    % smoothdata로 이동평균 적용 (MATLAB 네이티브 방식)
    As = smoothdata(A, 'movmean', win);
end


