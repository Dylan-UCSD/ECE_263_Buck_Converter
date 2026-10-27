
%% NCH 1.2 LVT Stacked
Cgg = 350*10^-15;
Ron = 8.1;
w = 200*10^-6; % 100u width each, but 1.2V so two are stacked

Cgs = 0.5*Cgg;
Cgd = 0.5*Cgg;
Cds = 0.8*Cgg;
Ciss = Cgd + Cgs;
Coss = Cds + Cgd;

Vin = 1.8;
Vds = Vin;
Vgs = 1;
Vout = 0.8;
D = Vout/Vin;
Iout = 1;

Irms_n = ((Iout^2)*(1-D))^0.5;



freqs = linspace(20*10^6,100*10^6,5);
widths = linspace(0,0.2, 10000);

loss = zeros([numel(freqs), numel(widths)]);


figure(1)

for n = 1:numel(freqs)
    for m = 1:numel(widths)


    Psw = Vds^2 * (Coss*widths(m)/w) * freqs(n);
    Pdr = Vgs^2 * (Cgg*widths(m)/w) * freqs(n);
    Pcond = Irms_n^2 * (Ron*w/widths(m));
    Ptot = Psw + Pdr + Pcond;
    loss(n,m) = Ptot;

    end
    plot(widths*10^6, loss(n,:), "LineWidth", 2);
    hold on
end
hold off
ylim([0,0.5])
legend("20M", "40M", "60M", "80M", "100M")
title("NMOS Loss vs Width")
xlabel("Switch Width (um)")
ylabel("Loss Power (W)")
grid on

minloss = zeros([1, numel(freqs)]);
minidx = zeros([1, numel(freqs)]);
minwidth = zeros([1, numel(freqs)]);
for n = 1:numel(freqs)


    [minloss(n), minidx(n)] = min(loss(n,:));
    minwidth(n) = widths(minidx(n));


end


figure(2)
plot(freqs*10^-6,minwidth*10^6, "LineWidth", 3);
grid on
title("Optimal NMOS Width vs Frequency")
xlabel("Frequency (MHz)")
ylabel("Width (um)")



%% PCH 1.2 LVT Stacked
Cgg = 0.2*10^-12;
Ron = 30;
w = 200*10^-6; % 100u width each, but 1.2V so two are stacked

Cgs = 0.5*Cgg;
Cgd = 0.5*Cgg;
Cds = 0.8*Cgg;
Ciss = Cgd + Cgs;
Coss = Cds + Cgd;

Vin = 1.8;
Vds = Vin;
Vgs = 1;
Vout = 0.8;
D = Vout/Vin;
Iout = 1;

Irms_n = ((Iout^2)*(1-D))^0.5;



freqs = linspace(20*10^6,100*10^6,5);
widths = linspace(0,0.2, 10000);

loss = zeros([numel(freqs), numel(widths)]);


figure(3)

for n = 1:numel(freqs)
    for m = 1:numel(widths)


    Psw = Vds^2 * (Coss*widths(m)/w) * freqs(n);
    Pdr = Vgs^2 * (Cgg*widths(m)/w) * freqs(n);
    Pcond = Irms_n^2 * (Ron*w/widths(m));
    Ptot = Psw + Pdr + Pcond;
    loss(n,m) = Ptot;

    end
    plot(widths*10^6, loss(n,:), "LineWidth", 2);
    hold on
end
hold off
ylim([0,0.5])
legend("20M", "40M", "60M", "80M", "100M")
title("PMOS Loss vs Width")
xlabel("Switch Width (um)")
ylabel("Loss Power (W)")
grid on

minloss = zeros([1, numel(freqs)]);
minidx = zeros([1, numel(freqs)]);
minwidth = zeros([1, numel(freqs)]);
for n = 1:numel(freqs)


    [minloss(n), minidx(n)] = min(loss(n,:));
    minwidth(n) = widths(minidx(n));


end


figure(4)
plot(freqs*10^-6,minwidth*10^6, "LineWidth", 3);
grid on
title("Optimal PMOS Width vs Frequency")
xlabel("Frequency (MHz)")
ylabel("Width (um)")

%% Inductor
% Set maximum allowable current ripple = minimum output current
IL_min = 0.2;

Vin_min = 1.6;
Vin_nom = 1.8;
Vin_max = 2;
Vout_min = 0.6;
Vout_nom = 0.8;
Vout_max = 1.2;

ind = linspace(0,100*10^-9, 1000);

fsw = 80*10^6;

dI_nomnom = ((Vin_nom-Vout_nom)*(Vout_nom/Vin_nom))./(fsw.*ind);
dI_maxmax = ((Vin_max-Vout_max)*(Vout_max/Vin_max))./(fsw.*ind);
dI_minmin = ((Vin_min-Vout_min)*(Vout_min/Vin_min))./(fsw.*ind);
dI_maxmin = ((Vin_max-Vout_min)*(Vout_min/Vin_max))./(fsw.*ind);
dI_minmax = ((Vin_min-Vout_max)*(Vout_max/Vin_min))./(fsw.*ind);

figure(5)
plot(ind,dI_nomnom)
hold on
plot(ind,dI_maxmax)
plot(ind,dI_minmin)
plot(ind,dI_maxmin)
plot(ind,dI_minmax)
hold off
ylim([0,1]);
grid on
xlabel("Inductance (H)")
ylabel("Current Ripple (A)")
title("Current Ripple vs Inductance @ 80MHz")
yline(IL_min)
legend("Vin: Nom, Vout: Nom", "Vin: Max, Vout: Max", "Vin: Min, Vout: Min", "Vin: Max, Vout: Min", "Vin: Min, Vout: Max", "Max Ripple")


freqs = linspace(20*10^6,100*10^6,5);
dI = zeros([numel(freqs), numel(ind)]);
figure(6)

for n = 1:numel(freqs)

    dI(n,:) = ((Vin_nom-Vout_nom)*(Vout_nom/Vin_nom))./(freqs(n).*ind);
    plot(ind, dI(n,:))
    hold on

end
hold off
ylim([0,1]);
grid on
xlabel("Inductance (H)")
ylabel("Current Ripple (A)")
title("Current Ripple vs Inductance")
yline(IL_min)
legend("20MHz", "40MHz", "60MHz", "80MHz", "100MHz")

% Choose Inductor Size
% Set nominal I_rms value for inductor
Lchoose = 0.3*10^-7;
Irms_nom = 1;

L_area = linspace(0, 100, 1000);
L_loss = Irms_nom^2 * (Lchoose/(4*10^-9)) * 0.2 ./L_area;

figure(7)
plot(L_area, L_loss, "LineWidth",3)
ylim([0,1])
title("Inductor Loss vs Area")
xlabel("Area (mm^2)")
ylabel("Power Loss (W)")
grid on



% Output Capacitor
I_ripple_nom = ((Vin_nom-Vout_nom)*(Vout_nom/Vin_nom))./(fsw.*Lchoose);
Vo_ripple = 0.03;

Cout = I_ripple_nom/(8*Vo_ripple*fsw);





