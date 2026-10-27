clear

% Set Specs
Vin = 1.8;
Vout = 0.8;
Iout = 1;
CurrentRipple = 0.4;
VoltageRipple = 0.03;


% Set Transistor Params
UnitRon_n = 8.1;
UnitCgg_n = 350*10^-15;
UnitW_n = 200*10^-6;

UnitRon_p = 30;
UnitCgg_p = 0.2*10^-12;
UnitW_p = 200*10^-6;

L_n = 130*10^-9;
L_p = 130*10^-9;

PtoN_Width_Ratio = 1; % 1 for equal widths

% Set Oparational Params
fsw = 80*10^6;

%%

% Calculate extrapolated params
D = Vout/Vin;
Vsw = Vin/2;
Ip = Iout + CurrentRipple/2;
Iv = Iout - CurrentRipple/2;
Irms_n = sqrt((1-D)*(Ip*Iv + (1/3)*(Ip-Iv)^2));
Irms_p = sqrt((D)*(Ip*Iv + (1/3)*(Ip-Iv)^2));
Irms_L = sqrt(Ip^2 - Ip*CurrentRipple + (1/3)*CurrentRipple^2);
L = (Vout*(1-D))/(CurrentRipple*fsw);
Cout = CurrentRipple/(8*VoltageRipple*fsw);
C_area_mm2 = Cout/(100*10^-9);

% Set up and run loop
N_widths = linspace(10^-2,10^-1, 20);
L_area = linspace(1,100, 20);

[NW, LA] = meshgrid(N_widths, L_area);
Efficiency = NW;
FOM = NW;

for n = 1:numel(L_area)
    for m = 1:numel(N_widths)
        % n row, m column

        W_n = NW(n,m);
        L_area_mm2 = LA(n,m);

        W_p = PtoN_Width_Ratio*W_n;

        Ron_n = UnitRon_n/(W_n/UnitW_n);

        Cgg_n = UnitCgg_n*(W_n/UnitW_n);
        Cgs_n = 0.5*Cgg_n;
        Cgd_n = 0.5*Cgg_n;
        Cds_n = 0.8*Cgg_n;
        Ciss_n = Cgd_n + Cgs_n;
        Coss_n = Cds_n + Cgd_n;
        
        Ron_p = UnitRon_p/(W_p/UnitW_p);
        Cgg_p = UnitCgg_p*(W_p/UnitW_p);
        Cgs_p = 0.5*Cgg_p;
        Cgd_p = 0.5*Cgg_p;
        Cds_p = 0.8*Cgg_p;
        Ciss_p = Cgd_p + Cgs_p;
        Coss_p = Cds_p + Cgd_p;

        N_area_mm2 = W_n*L_n*10^6;
        P_area_mm2 = W_p*L_p*10^6;

        Irms_n = sqrt((1-D)*(Ip*Iv + (1/3)*(Ip-Iv)^2));
        Irms_p = sqrt((D)*(Ip*Iv + (1/3)*(Ip-Iv)^2));
        Irms_L = sqrt(Ip^2 - Ip*CurrentRipple + (1/3)*CurrentRipple^2);
        
        Psw_n = Vin^2 * Coss_n * fsw;
        Pdr_n = Vsw^2 * Cgg_n * fsw;
        Pcond_n = Irms_n^2 * Ron_n;
        Ptot_n = Psw_n + Pdr_n + Pcond_n;
        
        Psw_p = Vin^2 * Coss_p * fsw;
        Pdr_p = Vsw^2 * Cgg_p * fsw;
        Pcond_p = Irms_p^2 * Ron_n;
        Ptot_p = Psw_p + Pdr_p + Pcond_p;

        Rdcr = (L/(4*10^-9))*(0.2/L_area_mm2);
        L_Loss = Irms_L^2 * Rdcr;
        PLoss = Ptot_n + Ptot_p + L_Loss;
        Pout = Vout*Iout;
        Efficiency(n,m) = (1+(PLoss/Pout))^-1;

        FOM(n,m) = PLoss*(N_area_mm2 + P_area_mm2 + L_area_mm2 + C_area_mm2);


    end
end

%% Plots
figure(1)
surf(LA,NW*10^6,Efficiency)
xlabel("Inductor Area (mm^2)")
ylabel("Switch Width (um)")
title("Efficiency")


figure(2)
surf(LA,NW*10^6,FOM)
zlim([0 20])
xlabel("Inductor Area (mm^2)")
ylabel("Switch Width (um)")
title("FOM")

figure(3)
[C,h] = contourf(LA,NW*10^6,Efficiency,15);
h.LevelList=floor(h.LevelList*100)/100;
clabel(C,h);
colorbar
colormap('Jet')
xlabel("Inductor Area (mm^2)")
ylabel("Switch Width (um)")
title("Efficiency")

figure(4)
[C,h] = contourf(LA,NW*10^6,FOM,50);
a = h.LevelList<5;
h.LevelList = h.LevelList(a);
h.LevelList=floor((h.LevelList)*10)/10;
clabel(C,h);
colorbar
colormap(flipud(jet))
xlabel("Inductor Area (mm^2)")
ylabel("Switch Width (um)")
title("FOM")







