warning('off','all');
%data_path = 'C:\Nguyen Pham\MY THESIS\database\longst\';
%data_path = 'C:\Nguyen Pham\MY THESIS\database\stchange\';
data_path = 'E:\ME_THESIS_GIT\database\euro\';
%data_path = 'C:\Nguyen Pham\MY THESIS\database\ecgid\pt1\';
% ECGID--------------------------------------------------------------------
%leads = ones(1,20) * 2;
% CAD----------------------------------------------------------------------
%recordings = [20011 20221 20271 20272 20273 20274 20461 20161 20361];
%leads = [2 1 2 2 2 2 1 1 2];
%recordings = [20011];
%leads = [2];
% recordings = [20011 20431 20221 20271 20272 20273 20274 20451 20461 20151 20161];
% SPSS Compatible Data Output
% recordings = [20431 20221 20271 20272 20273 20274 20451 20461 20151];
%-LONG ST------------------------------------------------------------------
%recordings = [20011 20431 20221 20271 20272 20151]; 
%leads = [2 1 1 2 2 1];
% R2 = 80%, 10s, 1/10 partition
% R2 = 70%, 30s, 1/10 partition -> Calculate STD
% R2 = 84.5%, 10s, 1/10 partition, trapz only -> Calculate STD
analysis = [];
%-ST CHANGES---------------------------------------------------------------
%recordings = [300 302 303 306 317];
%recordings = [302 306 312];
%leads = [1 1 1 1 1];
%-EUROPE-------------------------------------------------------------------
% recordings =  [103 104 105 106 112 118 121 129 139 133 162 161 154 613 612 704 801 808];
% leads =       [001 002 001 002 002 001 001 002 002 002 002 002 002 001 002 002 002 002];
% recordings = [122 154 161];
% leads = [2 1 2];
% recordings = [103 106 113 121 136 163 170 105 108 112 115 123 129 133 147 154 104 112 118 122 154 161];
% leads = [1 2 2 1 2 2 1 1 1 2 2 2 2 2 2 2 1 2 2 2 1 2];
recordings =    [103 104 105 106 112 113 118 121 129 133 136 139 154 161 162 163 170 105 108 112 115 123 129 133 147 154 104 112 118 122 154 161 612 801 808];
leads =         [001 002 001 002 002 002 001 001 002 002 002 002 002 002 002 002 001 001 001 002 002 002 002 002 002 002 001 002 002 002 001 002 002 002 002];
% recordings = 100:900;
% leads = ones(1,length(recordings)) * 2;
%-PARAMETERS-------------------------------
HR_bin = [];
meanHR_bin = []; % <----- For sliding window only
stdHR_bin = [];  % <----- For sliding window only
FFT_bin = [];
LFHF_bin = [];
DFA_bin = [];
Twave_bin = [];
ANN_bin = [];
FBAND_bin = [];
ENTROPY_bin = [];
STDeviation_bin = [];
meanSTDeviation_bin = []; % <----- For sliding window only
stdSTDeviation_bin = [];  % <----- For sliding window only
STslope_bin = [];
ENERGY_RATIO_bin = [];
ENTROPY_CUTOFF_bin = [];
%REPORT PARAMETERS---------------------------------------------------------
RP_STslope_bin = [];
RP_STdev_bin = [];
RP_HR_bin = [];
RP_DFA_bin = [];
RP_ENERGY_RATIO_bin = [];
RP_ENTROPY_CUTOFF_bin = [];
RP_Tinv_bin = [];
RP_ToR_bin = [];
score_bin = [];
failed_records = {};
%-HRV PARAMETERS-----------------------------------------------------------
HRV_std_bin = [];
HRV_minmax_bin = [];
HRV_min_bin = [];
HRV_max_bin = [];
HRV_DFA_bin = [];
% QUALIFYING DETECTION CODDE-----------------------------------------------
accepted = 0;
rejected = 0;
%------------------------------------------
for record = 1:length(recordings)
%for record = 1:20
    try
        %filename = ['s' num2str(recordings(record))];
        %filename = num2str(recordings(record));
        filename = ['e0' num2str(recordings(record))];
        %filename = ['rec_' num2str(record)];
        disp(filename);
        full_path = [data_path filename '.hea'];
        ECGw = ECGwrapper( 'recording_name', full_path);
        %load([data_path filename '_ECG_delineation.mat']);
        % READ SIGANL AND ANNOTATION-------------------------
        ann = ECGw.ECG_annotations;
        hea = ECGw.ECG_header;
        sig = ECGw.read_signal(1,hea.nsamp);
        sig1_raw = sig(:,leads(record));
        sig1_raw = sig1_raw(1:end);
        % NORMALIZATION CODES--------------------------------
        sig1_raw = sig1_raw - mean(sig1_raw);
        L = length(sig1_raw);
        Ex = 1/L * sum(abs(sig1_raw).^2);
        sig1_raw = sig1_raw / Ex;
        % BASELINE REMOVE USING Wavelet_decompose------------
        [approx, detail] = wavelet_decompose(sig1_raw, 8, 'db4');
        sig1 = sig1_raw - approx(:,8);
        %sig1 = sig1_raw;
        sig_backup = sig1;
        % NORMALIZA THE SIGNAL FROM 0 TO 1
        sig1 = sig1 + abs(min(sig1));
        sig1 = sig1 / max(sig1);
        % QRS DETECTION--------------------------------------
        %if exist('wqrs_ECGv1','var')
        %    QRS = wqrs_ECGv1.time;
        %elseif exist('wqrs_V4','var')
        %    QRS = wqrs_V4.time;
        %elseif exist('wqrs_V1','var')
        %    QRS = wqrs_V1.time;
        %elseif exist('wqrs_MLII','var')
        %    QRS = wqrs_MLII.time;
        %elseif exist('wqrs_MV2','var')
        %    QRS = wqrs_MV2.time;
        %elseif exist('wqrs_MV1','var')
        %    QRS = wqrs_MV1.time;
        %end;
        %QRS = wavedet;
        %fields = fieldnames(QRS);
        %fieldname = getfield(QRS,fields{leads(record)});
        % GENERAL PARAMETERS---------------------------------
        fs = hea.freq;
        ts = 1/fs;
        %beatNum = length(QRS);
        %annNum = length(ann.anntyp);
        % FFT PARAMETERS-------------------------------------
        FFT_beat_step = 30;
        FFT_part_of_total_data_used = 10;
        envelope_size = 26;
        smooth_type = 'loess';
        smooth_span = .01;
        % ---------------
        %       Pon: [111614x1 double]
        %         P: [111614x1 double]
        %      Poff: [111614x1 double]
        %     Ptipo: [111614x1 double]
        %     QRSon: [111614x1 double]
        %       qrs: [111614x1 double]
        %         Q: [111614x1 double]
        %         R: [111614x1 double]
        %         S: [111614x1 double]
        %    QRSoff: [111614x1 double]
        %       Ton: [111614x1 double]
        %         T: [111614x1 double]
        %    Tprima: [111614x1 double]
        %      Toff: [111614x1 double]
        %     Ttipo: [111614x1 double]
        %BEAT_TO_BEAT;
        %SLIDING_WINDOW;
        %WAVELET;
        try
            REPORT;
            %WAVELET;
        catch
            disp('An error occured while calibrating this record');
            failed_records{end + 1} = filename;
        end;
    catch
        disp(['record ' filename ' not found. Proceed to next one']);
    end;
end;
SCATTER_PLOT;
STATS;