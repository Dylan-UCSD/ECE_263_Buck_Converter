clear

Vin = 1.8;
Vout = 0.8;
D = Vout/Vin;

Iout = 1;
CurrentRipple = 0.4;

VoltageRipple = 0.03;

UnitRon_n = 8.1;
UnitCgg_n = 350*10^-15;
UnitW_n = 200*10^-6;

UnitRon_p = 30;
UnitCgg_p = 0.2*10^-12;
UnitW_p = 200*10^-6;

W_n = 0.1;
L_n = 130*10^-9;
W_p = 0.1;
L_p = 130*10^-9;

fsw = 80*10^6;
Vsw = Vin/2;

L_area_mm2 = 20;

N_area_mm2 = W_n*L_n*10^6;
P_area_mm2 = W_p*L_p*10^6;

%%
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


Ip = Iout + CurrentRipple/2;
Iv = Iout - CurrentRipple/2;

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

L = (Vout*(1-D))/(CurrentRipple*fsw);
Rdcr = (L/(4*10^-9))*(0.2/L_area_mm2);
L_Loss = Irms_L^2 * Rdcr;

Cout = CurrentRipple/(8*VoltageRipple*fsw);
C_area_mm2 = Cout/(100*10^-9);

PLoss = Ptot_n + Ptot_p + L_Loss;
Pout = Vout*Iout;
Efficiency = (1+(PLoss/Pout))^-1;

FOM = PLoss*(N_area_mm2 + P_area_mm2 + L_area_mm2 + C_area_mm2);

fprintf("Inductor: " + L*10^9 + "nH, " + L_area_mm2 + "mm^2 \n") 
fprintf("Capacitor: " + Cout*10^9 + "nF, " + C_area_mm2 + "mm^2 \n")
fprintf("Efficiency: " + Efficiency*100 + "%% \n")
fprintf("FOM: " +FOM+ "\n")



