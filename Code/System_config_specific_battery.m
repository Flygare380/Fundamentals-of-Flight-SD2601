clear all; close all; clc;

% Battery info: 
% https://www.grepow.com/semi-solid-state-battery/330wh-kg-series-high-energy-density-battery-pack.html

% Battery data for TARBG3333K18S10X (max constant discharge 99A)
batt_name   = "TARBG3333K18S10X";
U_land_off = 53.1;  % [V] Land-off voltage
U_rated = 66.6;     % [V] Rated voltage
I_max_cont = 99;    % [A] Max allowed continous amperage
I_max_temp = 330;   % [A] Max allowed temporary (15s) amperage
m_pack      = 7.009; % [kg] Mass per battery pack
E_specified = 313.59; % [Wh/kg] Manufacturer-specified specific energy 

% Power requirements
P_max_cont = 25e3;  % [W] Max power draw, continous
P_max_temp = 70e3;  % [W] Max power draw, temporary
E_use     = 0.85;   % [-] DoD, depth of discharge

% Battery config:
n = 12; % Number of battery packs
n_p = 2; % Number of parallell strings
n_s = n/n_p; % Number of packs in series

if mod(n, n_p) ~= 0
    error('n = %d packs cannot be split into %d equal parallel strings.', n, n_p);
end

% System voltages
V_batt_nom     = n_s * U_rated;      % [V] Nominal system voltage
V_batt_landOff = n_s * U_land_off;   % [V] Lowest system voltage

% Total battery energy and mass
m_batt_tot = n * m_pack;                     % [kg] Total battery mass
E_batt_tot = m_batt_tot * E_specified / 1e3; % [kWh] Total energy (manufacturer-specified)

% Currents at lowest voltage (land-off)
I_tot_cont  = P_max_cont / V_batt_landOff;   % [A] Total current
I_tot_temp  = P_max_temp / V_batt_landOff;
I_pack_cont = I_tot_cont / n_p;              % [A] Current per pack (shared by parallel strings)
I_pack_temp = I_tot_temp / n_p;

% Utilization
util_cont = I_pack_cont / I_max_cont;
util_temp = I_pack_temp / I_max_temp;

% Results
fprintf('Battery: %s, %d packs (%dS%dP)\n', batt_name, n, n_s, n_p);
fprintf('\nTotal energy:%7.1f kWh\nUsable energy: %5.1f kWh (DoD %.f%%)\nTotal mass:%9.1f kg\n', E_batt_tot, E_batt_tot*E_use, E_use*100, m_batt_tot);
fprintf('System voltage: %.1f V nominal, %.1f V at land-off\n\n', V_batt_nom, V_batt_landOff);

checkTxt = ["EXCEEDED", "OK"];
fprintf('%-12s %10s %12s %12s %10s %10s\n', 'Case', 'P [kW]', 'I_tot [A]', 'I_pack [A]', 'Limit [A]', 'Usage');
fprintf('%-12s %10.1f %12.1f %12.1f %10.0f %9.0f%%  %s\n', 'Continuous', ...
    P_max_cont/1e3, I_tot_cont, I_pack_cont, I_max_cont, 100*util_cont, checkTxt((util_cont <= 1) + 1));
fprintf('%-12s %10.1f %12.1f %12.1f %10.0f %9.0f%%  %s\n', 'Temp (15 s)', ...
    P_max_temp/1e3, I_tot_temp, I_pack_temp, I_max_temp, 100*util_temp, checkTxt((util_temp <= 1) + 1));

% Max allowed power with this configuration (at land-off voltage)
P_allow_cont = I_max_cont * n_p * V_batt_landOff;
P_allow_temp = I_max_temp * n_p * V_batt_landOff;
fprintf('\nMax allowed power (land-off): %.1f kW continuous, %.1f kW temporary\n', ...
    P_allow_cont/1e3, P_allow_temp/1e3);
