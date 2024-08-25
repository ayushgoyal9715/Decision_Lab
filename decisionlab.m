%% Initialize
clear; clc;

%% Set up EEGLAB directory and load EEGLAB
eeglab_dir = '../../Desktop/eeglab'; % Replace with your EEGLAB path
current_dir = pwd; % Save current directory

% Temporarily change directory to EEGLAB
cd(eeglab_dir);

% Start EEGLAB
eeglab;

% Close the EEGLAB GUI to avoid conflicts (optional but recommended)
close;

% Return to the original directory
cd(current_dir);

%% Path to data and subject ID
data_path = fullfile(current_dir, 'data');
subid = 48278;

%% Main processing loop
% disp(subid);

%% Load EEG data file
data_file = dir(fullfile(data_path, num2str(subid), '*.edf'));
data_file_path = fullfile(data_file(end).folder, data_file(end).name);
origchanlocs = readlocs(fullfile(data_path, 'Statnet_F3F4FCz.ced'));

%% Load EEG data
EEG = pop_biosig(data_file_path, 'channels', 1:19);

%% Drop channel EKG2
EEG = pop_select(EEG, 'rmchannel', 7);

%% Add an empty channel for FCz and update channel locations
EEG.data(end+1, :) = 0; % Add empty row for FCz
EEG.nbchan = size(EEG.data, 1);
EEG = pop_chanedit(EEG, 'load', fullfile(data_path, 'Statnet_F3F4FCz.ced'));


%% Re-reference to mastoids A1 A2, interpolate missing FCz, and re-reference to average
EEG = pop_reref(EEG, 4);  %A1
EEG = pop_reref(EEG, 1);  %A2
% EEG = pop_interp(EEG, origchanlocs);
EEG = pop_reref(EEG, []);

%% Test
% disp(origchanlocs.X[:2]);

% %% Bandpass filter
freqs = [0.5 80];
wtype = 'hamming'; df = 1; m = pop_firwsord(wtype, EEG.srate, df);
EEG = pop_firws(EEG, 'wtype', wtype, 'ftype', 'bandpass', 'fcutoff', freqs, 'forder', m);

%% Clean data with external function and EEGLAB function
EEG = clean_data_with_zapline_plus_eeglab_wrapper(EEG, struct('noisefreqs', 60, 'chunkLength', 0, 'adaptiveNremove', true, 'fixedNremove', 1, 'plotResults', 0));
EEG_asr = pop_clean_rawdata(EEG, 'FlatlineCriterion', 10, 'ChannelCriterion', 0.1, 'LineNoiseCriterion', 4, 'Highpass', [0.25 0.75], 'BurstCriterion', 20, 'WindowCriterion', 0.5, 'BurstRejection', 'off', 'Distance', 'Euclidian', 'WindowCriterionTolerances', [-Inf 10]);
 
%% Interpolate to original channel locations
% EEG_asr = pop_interp(EEG_asr, origchanlocs);
