L = 4.44e-9;
C = 41.7e-9;
Fs = 120e6; 
A0 = 60+5; %approx target gain in dB of op-amp

% 1/sqrt(LC) is the magnitude of the compelx conjugate pole pair
% Which is roughly speaking where the poles will come into effect (cutoff
% frequency of our LC filter. Peaking depends on the damping from the
% parasitic resistors.
Fp = 1 / (2 * pi * sqrt(L * C));
F_cross = Fp/10;
decades = A0 /20;

F_op_amp_pole = F_cross/10^(decades);
W_op_amp_pole = 2*pi*F_op_amp_pole;
fprintf('Pole of Op Amp with 60 dB of DC gain: %.3f Hz or %.3f Rad/s \n', F_op_amp_pole, W_op_amp_pole);


