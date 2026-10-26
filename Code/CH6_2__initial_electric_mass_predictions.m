clear all; close all; clc;

% Input
R       = 60;       % Range [km]
E       = 180;      % Mass energy density [Wh/kg]               % TODO: Research battery types
eta_tot = 0.70;     % Total power system efficiency [-]
mp      = 200;      % Payload [kg]

g = 9.807;
LDc_vec = 15:2.5:40;              % L/D (during cruise) to test
f_e_vec   = 0.40:0.05:0.70;     % Empty mass fraction me/m0 to test (empty mass without battery)

m0_tab   = NaN(length(f_e_vec), length(LDc_vec));
mbatt_tab = NaN(length(f_e_vec), length(LDc_vec));

for i = 1:length(f_e_vec)
    for j = 1:length(LDc_vec)
        f_e   = f_e_vec(i);
        LDc = LDc_vec(j);

        f_batt    = g*R / (3.6*E*eta_tot*LDc);              % Battery mass fraction mbatt/m0, (from 6-11)
        f_pay = 1 - f_e - f_batt;                           % Payload mass fraction mp/m0, denominator of (6-12)

        LDc_min = R*g / (3.6*(1-f_e)*E*eta_tot);            % Minimum L/D required for range R (6-13)
        if f_pay > 0 && LDc > LDc_min
            m0_tab(i,j)   = mp / f_pay;                     % Gross mass (6-12)
            mbatt_tab(i,j) = f_batt * m0_tab(i,j);          % Minimum battery mass [kg] (without any reserve), see (6-11)
        end
    end
end

% Result
disp('Gross mass m0 [kg]');
disp(array2table(round(m0_tab,1), 'VariableNames', ...
    strcat('LD_', string(LDc_vec)), 'RowNames', strcat('me/m0=', string(f_e_vec))));

fprintf('\nBattery mass mbatt [kg] for range R = %g km (no reserve)\n', R);
disp(array2table(round(mbatt_tab,1), 'VariableNames', ...
    strcat('LD_', string(LDc_vec)), 'RowNames', strcat('me/m0=', string(f_e_vec))));
