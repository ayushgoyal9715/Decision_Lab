import mne
from meegkit.dss import dss_line
import numpy as np

# Load your EEG data from the EDF file
# Replace 'data_path', 'subid', and 'Statnet_F3F4FCz.ced' with your actual paths and file names
data_file_path = r'C:\Users\91820\Downloads\drive-download-20240708T114910Z-001\15089_2017_08_14_EEG\0_20170814_161604.edf'  # Construct this based on your directory structure
chanlocs_path = r"C:\Users\91820\Downloads\sample_channel_location-20240703T173902Z-001\sample_channel_location\Statnet_F3F4FCz.ced" # Channel locations file

# Load the raw EEG data
raw = mne.io.read_raw_edf(data_file_path, preload=True)

# Drop channel EKG2
raw.drop_channels(['EKG2'])

# Add an empty channel FCz at index 19
n_channels, n_times = raw._data.shape
raw._data = np.vstack((raw._data, np.zeros((1, n_times))))
raw.info['chs'].append({'ch_name': 'FCz', 'coil_type': 1, 'kind': 2, 'logno': 19, 'scanno': 19,
                        'unit': 107, 'unit_mul': 0, 'range': 1.0, 'cal': 1.0, 'loc': np.zeros(12)})
raw.info['nchan'] += 1
raw.info['ch_names'].append('FCz')

# Load and set channel locations
montage = mne.channels.read_custom_montage(chanlocs_path)
raw.set_montage(montage)

# Re-reference to mastoid electrodes A1 and A2
raw.set_eeg_reference(ref_channels=['A1', 'A2'])

# Interpolate missing channels (e.g., FCz)
raw = raw.copy().interpolate_bads()

# Re-reference to the average
raw.set_eeg_reference(ref_channels='average')

# Bandpass filter
freqs = [0.5, 80]
raw.filter(l_freq=freqs[0], h_freq=freqs[1], fir_design='firwin', phase='zero')

# Apply zapline for adaptive noise removal
def apply_zapline(raw, freq, sfreq, n_remove=1):
    """Apply zapline (dss_line) to raw MNE data."""
    data = raw.get_data()
    data_clean, _, _ = dss_line(data, fline=freq, sfreq=sfreq, n_remove=n_remove)
    raw_clean = raw.copy()
    raw_clean._data = data_clean
    return raw_clean

noisefreqs = 60  # Frequency of the noise to be removed (Hz)
raw_clean = apply_zapline(raw, noisefreqs, raw.info['sfreq'])

# Optionally, plot the results
plot_results = False  # Set to True if you want to plot
if plot_results:
    raw.plot(n_channels=10, block=True, title='Original Data')
    raw_clean.plot(n_channels=10, block=True, title='Cleaned Data')

# Save the cleaned data in FIF format
# raw_clean.save('your_cleaned_eeg_file.fif', overwrite=True)
