clc;
clearvars;
close all;

%% Initial Parameters %%
S = 12.44;                                  % Wing reference area [m2]
S_HT = 1.11;                                % Horizontal tail planform area [m2]
S_e = 0.25*S_HT;                            % Elevator area [m2] (25% of S_HT)
b = 12.22;                                  % Wing span [m]
c = 1.07;                                   % Wing mean aerodynamic chord (MAC) [m]
c_HT = 0.47;                                % Horizontal tail MAC [m]
SM = 7.5;                                   % Total aircraft static margin [percent]
distance_LEWing_LEHT = 4.5;                 % Distance between wing LE and HT LE [m]
i_W = deg2rad(2.3);                         % Wing incidence angle [rad]
i_HT = deg2rad(-2.6);                       % Horizontal tail incidence angle [rad]

C_L_alpha_W = 0.092898*(180/pi);            % Wing lift curve slope [1/rad]
C_L_alpha_HT = 0.074245*(180/pi);           % HT lift curve slope [1/rad]
C_L_0_W = 0.4;                              % Wing lift coefficient at zero AoA
C_L_0_HT = 0;                               % HT lift coefficient at zero AoA
n_HT = 1;                                   % HT effectiveness factor
delta_e = deg2rad(0);                       % Elevator deflection angle [rad]

AR = b^2 / S;                               % Wing aspect ratio
r_e = S_e / S_HT;                           % Elevator area ratio
T_e = -4.66*r_e^4 + 8.79*r_e^3 - 6.44*r_e^2 + 2.85*r_e + 0.0316;

x_ac_W = (1/4)*c;                           % Wing AC wrt wing LE [m]
x_ac_HT = distance_LEWing_LEHT + (1/4)*c_HT;% HT AC wrt wing LE [m]

h_ac_W = x_ac_W / c;
h_ac_HT = x_ac_HT / c;

E0 = 2*C_L_0_W / (pi*AR);                   % Residual downwash [rad]
dE_dalpha = 2*C_L_alpha_W / (pi*AR);        % Downwash slope [-]

%Solution for Neutral Point (x_n) and CG (x_cg)
K = n_HT * (S_HT / S) * (C_L_alpha_HT / C_L_alpha_W) * (1 - dE_dalpha);

h_n = (h_ac_W + K * (h_ac_HT + SM/100)) / (1 + K);
h_cg = h_n - (SM/100);

x_n = h_n * c;                              % Neutral point wrt wing LE [m]
x_cg = h_cg * c;                            % Centre of gravity wrt wing LE [m]

l_HT_cg = x_ac_HT - x_cg;                   % Tail moment arm wrt CG [m]
V_HT = (S_HT * l_HT_cg) / (S * c);          % Horizontal tail volume coefficient [-]


%% Known equations for NACA 4415 %%
C_M_ac_W = -0.103; %Pitching Moment coefficient about quarter chord/AC %%%André%%%

%% Known equations for NACA 0012 %%
%Symmetric:
C_M_ac_HT = 0;

%%	Determining the downwash angle %%

alpha_W = @(alpha) alpha + i_W; %AoA at Wing

E0 = 2*C_L_0_W/(pi*AR); %residual downwash 
dE_dalpha = 2*C_L_alpha_W/(pi*AR); %Downwash angle
E = @(alpha) E0+dE_dalpha*alpha_W(alpha); %Total downwash

alpha_HT = @(alpha) alpha_W(alpha) - E(alpha) + i_HT; %AoA at Horizontal Tail

% GRAPH 1: Downwash angle
figure;
fplot(@(alpha_deg) rad2deg(E(deg2rad(alpha_deg))), [-15 15], 'b-', 'LineWidth', 2);
grid on;
xlabel('Far-field angle of attack (fuselage AoA), \alpha [deg]');
ylabel('Downwash angle, \epsilon [deg]');
title('Downwash Angle vs. Far-field Angle of Attack');

% GRAPH 2: Horizontal tail angle of attack
figure;
fplot(@(alpha_deg) rad2deg(alpha_HT(deg2rad(alpha_deg))), [-15 15], 'r-', 'LineWidth', 2);
grid on;
xlabel('Far-field angle of attack (fuselage AoA), \alpha [deg]');
ylabel('Horizontal tail angle of attack, \alpha_{HT} [deg]');
title('Horizontal Tail Angle of Attack vs. Far-field Angle of Attack');

h_n = h_ac_W + n_HT*V_HT*(C_L_alpha_HT/C_L_alpha_W)*(1-dE_dalpha); %p.38
x_n = h_n*c;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% THE MOMENT MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculating the Pitching Moment Coefficient %%

% Residual Pitching Moment Coefficient %

C_M_0_W = C_M_ac_W + C_L_0_W*(h_cg-h_ac_W);
C_M_0_HT = C_M_ac_HT + C_L_0_HT*(l_HT_cg/c);


% Longitudinal Stability Derivative %

            %Classical%
C_M_alpha_W = C_L_alpha_W*(h_cg-h_ac_W);
C_M_alpha_HT = -n_HT*V_HT*C_L_alpha_HT*(1-dE_dalpha);

            %Special%
%C_M_q = 1.1*(-2*C_l_alpha_HT*n_HT*(S_HT/S)*l_HT_cg^2); %Pitch Damping %Coefficient = 1.1*C_M_q_HT; This dynamic component is not used for straight, steady-state flight
%C_M_alphadot = 0;%-2*C_l_alpha_HT*n_HT*V_HT*(l_HT_cg/c)*dE_dalpha; %Change in pitching moment due to downwash = C_M_alphadot_HT; This dynamic component is not used for straight, steady-state flight
C_M_i_HT = -n_HT*C_L_alpha_HT*V_HT; %Change in pitching moment due to HT incidence
        dC_L_HT_ddelta_e = C_L_alpha_HT*T_e ; %dC_L_HT/ddelta_e
C_M_delta_e = (n_HT*(S_HT/S)*(h_cg-h_ac_W) -V_HT) * dC_L_HT_ddelta_e; %Change in pitching moment due to elevator


%%%Finally:
C_M_W = @(alpha) C_M_0_W + C_M_alpha_W*alpha_W(alpha); %wing-specific
C_M_HT = @(alpha) C_M_0_HT + C_M_alpha_HT*alpha_W(alpha) + C_M_i_HT*i_HT + C_M_delta_e*delta_e;% + C_M_q + C_M_alphadot; %HT-specific
C_M_HT_e0 = @(alpha) C_M_0_HT + C_M_alpha_HT*alpha_W(alpha) + C_M_i_HT*i_HT;%Without elevator
C_M = @(alpha) C_M_W(alpha) + C_M_HT(alpha);
C_M_e0 = @(alpha) C_M_W(alpha) + C_M_HT_e0(alpha);

%%%GRAPH:
% GRAPH 3: Pitching moment coefficient

figure('Color','w');
hold on;
grid on;

if delta_e ~= 0
    fplot(@(alpha_deg) C_M_e0(deg2rad(alpha_deg)), [-15 15], '--', 'Color', [1, 0, 1], 'LineWidth', 2.5);
end
fplot(@(alpha_deg) C_M(deg2rad(alpha_deg)), [-15 15], 'Color', [1, 0, 1], 'LineWidth', 2.5);
fplot(@(alpha_deg) C_M_W(deg2rad(alpha_deg)), [-15 15], 'Color', [0.25, 0.88, 0.82], 'LineWidth', 2.5);
fplot(@(alpha_deg) C_M_HT(deg2rad(alpha_deg)), [-15 15], 'Color', [1 0.5 0], 'LineWidth', 2.5);

ax = gca;
ax.FontSize = 12;
ax.GridAlpha = 0.2;

xlabel('Far-field Angle of attack (fuselage AoA), \alpha [deg]');
ylabel('Moment coefficient, C_M [-]');

if delta_e == 0
    legend('Total moment coefficient', 'Wing moment coefficient', 'Horizontal tail moment coefficient', 'Location', 'best');
else
    legend('Total moment coefficient without elevator','Total moment coefficient', 'Wing moment coefficient', 'Horizontal tail moment coefficient', 'Location', 'best');
end


%%%Final Results%%%

%Neutral Point
disp("%%% NEUTRAL POINT %%%")
h_n = h_ac_W + n_HT*V_HT*(C_L_alpha_HT/C_L_alpha_W)*(1-dE_dalpha); %p.38
x_n = h_n*c;
fprintf("The total aircraft's stick-fixed neutral point/aerodynamic centre is: %.4f [m]\n",x_n);
fprintf("The wing's aerodynamic centre, which is the reference in the equations, is: %.4f [m]\n",x_ac_W);

% Static margin
disp("%%% STATIC MARGIN %%%")
fprintf("The static margin is: %.4f [percent]\n", SM);

% Pitching Moment Coefficient Equation
disp("%%% PITCHING MOMENT COEFFICIENT %%%")
sym_CM = sym(C_M);
disp('Symbolic pitching moment coefficient expression:');
disp(sym_CM);

disp("where")

fprintf("Residual Pitching Moment is: %.4f [1/rad]\n",C_M_0_W + C_M_0_HT + C_M_i_HT*i_HT + C_M_delta_e*delta_e)
fprintf("Longitudinal static derivative is: %.4f [1/rad]\n", C_M_alpha_W + C_M_alpha_HT)

% Trim angle: Alpha at coefficient zero:
disp("%%% TRIM ANGLE %%%")
alpha_zero = fzero(C_M, 0);
alpha_zero_deg = rad2deg(alpha_zero);
disp("Aiming for a trim angle of 0 degrees to maintain cruising speed of 130 km/h = TRIM SPEED")
fprintf("TRIM ANGLE: Angle of Attack at which the Pitching Moment Coefficient is zero is: %.2f [deg]\n", alpha_zero_deg);

% Tail Moment Arm
disp("%%% TAIL MOMENT ARM %%%")
fprintf("Horizontal tail moment arm is: %.4f [m]\n", l_HT_cg);

% Tail Efficiency Factor
disp("%%% Tail Efficiency Factor %%%");
fprintf("Horizontal tail efficiency factor is: %.4f\n", n_HT);
disp("Because wind tunnel and CFD wake-survey data are unavailable at this preliminary design stage, the analytical equations from Gudmundsson (Section 24.2.9) cannot be directly evaluated. Instead, a standard tail efficiency factor of 1.00 is adopted for a conventional (T-Tail) configuration, accounting for minor dynamic pressure differences due to the propwash and fuselage.")

% Elevator Size
disp("%%% ELEVATOR SIZE %%%");
fprintf("Elevator-to-tail chord ratio is: %.4f\n", T_e);
fprintf("Elevator control effectiveness per difference of elevator angle C_M_delta_e is: %.4f [1/rad]\n", C_M_delta_e);
fprintf("Elevator Area is: %.4f [m2]\n", S_e);