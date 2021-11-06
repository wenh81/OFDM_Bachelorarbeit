clc;
clear;
%OFDM
%% Declare parameters

N_sub = 4096;                   %Anzahl der Unterträger
symbol_size = 4;                %Symbolgröße z.B. 2 für 4-Qam oder 4 für 16-QAM
signal_length = 100;            %Signallänge in OFDM Symbolen
cp_size = ceil(N_sub/(10*symbol_size)); %cyclic prefix Länge

taps = [0.2,0.1,0.02,0.05,0.05];%Gewichtung der einzelnen Verzögerungen
delays = [1,2,3,4,5];           %Verzögerungen des Kanals

%% generate signal

input_signal = randi([0 1],1,N_sub * signal_length);

%% serial to parallel
%konvertiert den seriellen Datenstrom in N_sub parallele Datenströme 

parallel = serial_to_parallel(input_signal,N_sub,symbol_size);

%% QAM
%Bits werden in QAM-Symbole moduliert

QAM_modulated  = QAM(parallel);

%% IFFT
%Die IFFT der parallelen Symbole wird berechnet

for j = 1 : length(QAM_modulated(1,:))
    x = j * length(QAM_modulated(:,1)) - length(QAM_modulated(:,1)) + 1;
    y = j * length(QAM_modulated(:,1));
    ifft_array (x:y) = ifft(QAM_modulated(:,j)); 
end

ifft_array = (ifft_array); %abs?
%% cyclic prefix

cp = cyclic_prefix(ifft_array,cp_size,N_sub);

%% shift to passband

%% Channel
%Tapped Dealy channel 

channel_array = tapped_delay_channel(cp,taps,delays);

%% shift to baseband

%% remove cyclic prefix

no_cp = remove_cp (channel_array,cp_size,N_sub);

%% FFT
%FFT wird von einem OFDM Symbol gebildet, das die Länge von N_sub hat

ifft_array_serial = serial_to_parallel(no_cp,N_sub,1);

for j = 1 : (signal_length/symbol_size)
    x = j * N_sub - N_sub + 1;
    y = j * N_sub;
    fft_array(x:y) = fft(ifft_array_serial(:,j)); 
end

%% demodulate QAM
%QAM-Symbole werden in Bits demoduliert

QAM_demodulated = QAM_demod(fft_array,symbol_size);

%% parallel to serial

output_signal = parallel_to_serial(QAM_demodulated);

%% test plots

figure('Name' , "Plots");
hold on;
subplot(2,1,1);
BER = output_signal - input_signal;
plot(1:length(BER),BER);

subplot(2,1,2);
z = interp(ifft_array(1,1:256),4);
plot(-length(z)/2:length(z)/2-1,fftshift(abs(fft(z))));

