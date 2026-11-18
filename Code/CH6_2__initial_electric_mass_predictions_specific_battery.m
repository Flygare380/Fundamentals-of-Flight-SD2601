clear all; close all; clc;

% Battery info: 
% https://www.grepow.com/semi-solid-state-battery/330wh-kg-series-high-energy-density-battery-pack.html

% Battery data for TARBG3395K18S10X (max constant discharge 285A)
%batt_name   = "TARBG3395K18S10X";
%m_pack      = 20.5851;       % Mass per battery pack [kg]
%E_specified = 307.36;        % Manufacturer-specified specific energy [Wh/kg]

% Battery data for TARBG3333K18S10X (max constant discharge 99A)
batt_name   = "TARBG3333K18S10X";
m_pack      = 7.009;       % Mass per battery pack [kg]
E_specified = 313.59;        % Manufacturer-specified specific energy [Wh/kg]


% Mission and aircraft inputs
R_planned = 120;             % Planned total flight distance, including return [km]
R_margin  = 1.1;             % Flight-distance margin factor [-]
E_use     = 0.85;            % DoD, depth of discharge [-]
eta_tot   = 0.70;            % Total system efficiency [-]
mp        = 200;             % Payload mass, retained throughout  mission [kg]
g         = 9.807;           % [m/s^2]

E = E_specified * E_use;     % Specific energy available [Wh/kg]
R = R_planned * R_margin;   % Design flight distance [km]

LDc_vec = 12:1.5:24;           % Cruise lift-to-drag ratios to evaluate [-]
f_e_vec = 0.45:0.05:0.70;    % Empty mass fractions, excluding batteries, me/m0 [-]

m0_tab = NaN(length(f_e_vec), length(LDc_vec));
nbatt_tab = NaN(length(f_e_vec), length(LDc_vec));
R_tab = NaN(length(f_e_vec), length(LDc_vec));
R_margin_tab = NaN(length(f_e_vec), length(LDc_vec));

for i = 1:length(f_e_vec)
    for j = 1:length(LDc_vec)
        f_e = f_e_vec(i);
        LDc = LDc_vec(j);

        % Theoretic mass fractions
        f_batt_theor = g*R / (3.6*E*eta_tot*LDc);
        f_pay_theor = 1 - f_e - f_batt_theor;

        % Min cruise L/D required
        LDc_min = R*g / (3.6*(1-f_e)*E*eta_tot);

        if f_pay_theor > 0 && LDc > LDc_min

            % Gross mass and battery mass (continuous battery mass)
            m0_theor = mp / f_pay_theor;
            mbatt_theor = f_batt_theor * m0_theor;

            % Number of whole packs
            N_batt = ceil(mbatt_theor / m_pack);

            % Recalculate gross mass using the actual integer battery packs
            % Mass balance: m0 = m_empty + m_payload + m_batt
            % Since m_empty = f_e*m0:
            % thus m0 = (mp + N_batt*m_pack)/(1 - f_e)
            m0_actual = (mp + N_batt * m_pack) / (1 - f_e);

            mbatt_actual = N_batt * m_pack;
            f_batt_actual = mbatt_actual / m0_actual;
            R_actual = 3.6 * E * eta_tot * LDc * f_batt_actual / g;

            m0_tab(i,j) = m0_actual;
            nbatt_tab(i,j) = N_batt;
            R_tab(i,j) = R_actual;
            R_margin_tab(i,j) = R_actual - R;
        end
    end
end

% Display results
disp('Take-off weight m0 [kg] (using integer number of battery packs):');
disp(array2table(round(m0_tab,1), 'VariableNames', ...
    strcat('LD_', string(LDc_vec)), ...
    'RowNames', strcat('me_m0_', string(f_e_vec))));

fprintf('\nBattery mass mbatt [kg] (%s, integer number of packs):\n', batt_name);
disp(array2table(round(nbatt_tab * m_pack, 1), 'VariableNames', ...
    strcat('LD_', string(LDc_vec)), ...
    'RowNames', strcat('me_m0_', string(f_e_vec))));


fprintf('\nNumber of battery packs (%s) for design range R = %g km:\n', batt_name, R);
disp(array2table(nbatt_tab, 'VariableNames', ...
    strcat('LD_', string(LDc_vec)), ...
    'RowNames', strcat('me_m0_', string(f_e_vec))));

fprintf('\nAchievable range [km] using integer battery packs:\n');
disp(array2table(round(R_tab,1), ...
    'VariableNames', strcat('LD_', string(LDc_vec)), ...
    'RowNames', strcat('me_m0_', string(f_e_vec))));

fprintf('\nExtra range beyond design requirement [km]:\n');
disp(array2table(round(R_margin_tab,1), ...
    'VariableNames', strcat('LD_', string(LDc_vec)), ...
    'RowNames', strcat('me_m0_', string(f_e_vec))));