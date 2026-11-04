Vout = 0.8;
Vin = 1.8;

Iout = 1;
inductor_ripple = 0.8;

f = 100e6;
Rseries = 0.01:0.0001:0.3;

Vo_target = Vout + Rseries*Iout;
dutyCycle = Vo_target / Vin;

eff_target = 0.87;
loss = Rseries*Iout;
pl= 0.8;
eff = pl./(loss+pl);

area = L./(4e-9)*200./(Rseries*1000)*4/3;
FOM = area*0.5.*(1-eff)./eff;
plot(Rseries, dutyCycle);
xlabel("Series Resistance (Ohms)")
ylabel("Duty Cycle of Buck Converter")

L = (Vo_target).*(1-dutyCycle)/(inductor_ripple*f);
figure;
plot(Rseries, L);
xlabel("Series Resistance (Ohms)");
ylabel("Inductance (H)");
grid on;


figure;
plot(Rseries, eff*100);
xlabel("Series Resistance (Ohms)");
ylabel("Efficiency (%)");
grid on;

figure;
plot(Rseries, eff*100);
xlabel("Series Resistance (Ohms)");
ylabel("Efficiency (%)");
grid on;

figure;
plot(Rseries, area);

xlabel("Series Resistance (Ohms)");
ylabel("Area (mm)");
grid on;

figure;

plot(Rseries, area);

xlabel("Series Resistance (Ohms)");
ylabel("FOM");
grid on;