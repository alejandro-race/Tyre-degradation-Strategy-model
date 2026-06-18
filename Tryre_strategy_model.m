%% TYRE DEGRADATION & PIT WINDOW OPTIMIZATION MODEL
% Author: Alejandro Álvarez Martín

% Description:
% Simplified tyre degradation and race strategy model including:
% - Non-linear tyre degradation
% - Fuel burn-off effect
% - One-stop strategy simulation
% - Optimal pit stop lap identification
% - Strategy comparison

clear; clc; close all;

% =========================
%  1. GENERAL PARAMETERS
%  =========================

race.laps = 50;                     % Total race laps
race.pitLoss = 22.0;                % Pit stop time loss [s]
race.fuelEffect = 0.035;            % Lap time gain per lap due to fuel burn-off [s/lap]

% Pit window to evaluate
pitWindow = 8:42;

% =========================
%  2. TYRE COMPOUND PARAMETERS
%  =========================
% Lap time model:
% LapTime = basePace + a*TyreAge + b*TyreAge^2 - c*RaceLap
%
% BasePace: initial lap time of the compound
% a: linear degradation coefficient
% b: non-linear degradation coefficient
% c: fuel burn-off effect

compounds.Soft.name = "Soft";
compounds.Soft.basePace = 92.00;
compounds.Soft.fuelSensitivity = 0.45;
compounds.Soft.maxStint = 18;
compounds.Soft.degLinear = 0.035;
compounds.Soft.degQuad = 0.0045;
compounds.Soft.color = [0.85 0.10 0.10];

compounds.Medium.name = "Medium";
compounds.Medium.basePace = 92.70;
compounds.Medium.fuelSensitivity = 0.25;
compounds.Medium.maxStint = 30;
compounds.Medium.degLinear = 0.025;
compounds.Medium.degQuad = 0.0025;
compounds.Medium.color = [0.95 0.65 0.10];

compounds.Hard.name = "Hard";
compounds.Hard.basePace = 93.30;
compounds.Hard.fuelSensitivity = 0.12;
compounds.Hard.maxStint = 42;
compounds.Hard.degLinear = 0.015;
compounds.Hard.degQuad = 0.0012;
compounds.Hard.color = [0.15 0.15 0.15];


% =========================
%  3. DEFINE STRATEGIES
%  =========================

strategies = {
    "Soft",   "Medium";
    "Soft",   "Hard";
    "Medium", "Soft";
    "Medium", "Hard";
    "Hard",   "Soft";
    "Hard",   "Medium"
};

nStrategies = size(strategies, 1);

% =========================
%  4. PLOT TYRE BEHAVIOUR
%  =========================

stintLaps = 1:35;
raceLapReference = 1:35;

figure('Name','Tyre Compound Behaviour','Color','w');
hold on; grid on; box on;

compoundNames = fieldnames(compounds);

for i = 1:length(compoundNames)
    compound = compounds.(compoundNames{i});

    lapTimes = zeros(size(stintLaps));

    for j = 1:length(stintLaps)
        tyreAge = stintLaps(j) - 1;
        raceLap = raceLapReference(j) - 1;
        lapTimes(j) = calculateLapTime(compound, tyreAge, raceLap, race);
    end

    plot(stintLaps, lapTimes,'LineWidth', 2.4,'Color', compound.color,'DisplayName', compound.name);
end

xlabel('Tyre age [laps]', 'FontWeight','bold');
ylabel('Estimated lap time [s]', 'FontWeight','bold');
title('Non-linear Tyre Degradation Model', 'FontWeight','bold');
legend('Location','northwest');
set(gca, 'FontSize', 11);

exportgraphics(gcf, '01_tyre_degradation_model.png', 'Resolution', 300);

% =========================
%  5. STRATEGY OPTIMIZATION
%  =========================

results = struct();

for s = 1:nStrategies

    firstCompoundName = strategies{s,1};
    secondCompoundName = strategies{s,2};

    firstCompound = compounds.(firstCompoundName);
    secondCompound = compounds.(secondCompoundName);

    [bestPitLap, bestRaceTime, raceTimesByPitLap, bestLapTimes] = optimizeOneStopStrategy(firstCompound, secondCompound, race, pitWindow);

    strategyName = firstCompoundName + "-" + secondCompoundName;

    results(s).strategy = strategyName;
    results(s).firstCompound = firstCompoundName;
    results(s).secondCompound = secondCompoundName;
    results(s).bestPitLap = bestPitLap;
    results(s).bestRaceTime = bestRaceTime;
    results(s).raceTimesByPitLap = raceTimesByPitLap;
    results(s).bestLapTimes = bestLapTimes;

end

% =========================
%  6. RESULTS TABLE
%  =========================

strategyNames = strings(nStrategies,1);
bestPitLaps = zeros(nStrategies,1);
bestRaceTimes = zeros(nStrategies,1);

for s = 1:nStrategies
    strategyNames(s) = results(s).strategy;
    bestPitLaps(s) = results(s).bestPitLap;
    bestRaceTimes(s) = results(s).bestRaceTime;
end

summaryTable = table(strategyNames, bestPitLaps, bestRaceTimes, 'VariableNames', {'Strategy','OptimalPitLap','TotalRaceTime_seconds'});

summaryTable = sortrows(summaryTable, 'TotalRaceTime_seconds');

disp(' ');
disp('==============================================');
disp(' STRATEGY OPTIMIZATION RESULTS');
disp('==============================================');
disp(summaryTable);

bestOverallStrategy = summaryTable.Strategy(1);
bestOverallPitLap = summaryTable.OptimalPitLap(1);
bestOverallTime = summaryTable.TotalRaceTime_seconds(1);

fprintf('\nBest overall strategy: %s\n', bestOverallStrategy);
fprintf('Optimal pit lap: Lap %d\n', bestOverallPitLap);
fprintf('Minimum race time: %.2f s\n', bestOverallTime);

% =========================
%  7. PLOT PIT WINDOW OPTIMIZATION
%  =========================

figure('Name','Pit Window Optimization','Color','w');
hold on; grid on; box on;

for s = 1:nStrategies

    raceTimes = results(s).raceTimesByPitLap;

    plot(pitWindow, raceTimes, 'LineWidth', 2.0, 'DisplayName', results(s).strategy);

    % Mark each strategy optimum
    plot(results(s).bestPitLap, results(s).bestRaceTime, 'o', 'MarkerSize', 7, 'LineWidth', 1.8, 'HandleVisibility','off');

end

xlabel('Pit stop lap', 'FontWeight','bold');
ylabel('Total race time [s]', 'FontWeight','bold');
title('Pit Window Optimization by Strategy', 'FontWeight','bold');
legend('Location','best');
set(gca, 'FontSize', 11);

exportgraphics(gcf, '02_pit_window_optimization.png', 'Resolution', 300);

% =========================
%  8. PLOT BEST STRATEGY LAP TIME PROFILE
%  =========================

% Find best strategy index
bestIndex = find(strategyNames == bestOverallStrategy);
bestLapTimes = results(bestIndex).bestLapTimes;

figure('Name','Best Strategy Lap Time Profile','Color','w');
hold on; grid on; box on;

plot(1:race.laps, bestLapTimes, 'LineWidth', 2.2, 'Color', [0.10 0.25 0.65]);

xline(bestOverallPitLap, '--', 'Pit stop', 'LineWidth', 1.8, 'LabelVerticalAlignment','bottom');

xlabel('Race lap', 'FontWeight','bold');
ylabel('Lap time [s]', 'FontWeight','bold');
title("Best Strategy Lap Time Profile: " + bestOverallStrategy, 'FontWeight','bold');
set(gca, 'FontSize', 11);

exportgraphics(gcf, '03_best_strategy_lap_profile.png', 'Resolution', 300);


% =========================
%  9. PLOT STRATEGY COMPARISON BAR CHART
%  =========================

figure('Name','Strategy Comparison','Color','w');

bar(categorical(summaryTable.Strategy), summaryTable.TotalRaceTime_seconds);
grid on; box on;

xlabel('Strategy', 'FontWeight','bold');
ylabel('Total race time [s]', 'FontWeight','bold');
title('Total Race Time Comparison', 'FontWeight','bold');
set(gca, 'FontSize', 11);

% Adjust Y-axis to highlight differences
minTime = min(summaryTable.TotalRaceTime_seconds);
maxTime = max(summaryTable.TotalRaceTime_seconds);
margin = 5; % seconds of visual margin

ylim([minTime - margin, maxTime + margin]);

% Rotate labels for readability
xtickangle(25);

% Add value labels above each bar
for i = 1:height(summaryTable)
    text(i, summaryTable.TotalRaceTime_seconds(i) + 0.5, ...
        sprintf('%.2f s', summaryTable.TotalRaceTime_seconds(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize', 9);
end

exportgraphics(gcf, '04_strategy_comparison.png', 'Resolution', 300);

% =========================
%  LOCAL FUNCTIONS
%  =========================

function lapTime = calculateLapTime(compound, tyreAge, raceLap, race)

    % Fuel burn-off effect: the car becomes faster as fuel mass decreases
    fuelBurnOffGain = race.fuelEffect * raceLap;

    % Fuel load factor: 1 at the start, 0 at the end
    fuelLoadFactor = 1 - raceLap / (race.laps - 1);

    % Tyre stress due to high fuel load
    fuelStressMultiplier = 1 + compound.fuelSensitivity * fuelLoadFactor;

    % Base tyre degradation corrected by fuel-load stress
    tyreDegradation = fuelStressMultiplier * (compound.degLinear * tyreAge + compound.degQuad * tyreAge^2);

    % Tyre cliff penalty
    cliffPenalty = 0;

    if isfield(compound, 'maxStint') && tyreAge > compound.maxStint
        lapsOverLimit = tyreAge - compound.maxStint;
        cliffPenalty = 0.04 * lapsOverLimit^2;
    end

    % Final lap time
    lapTime = compound.basePace + tyreDegradation + cliffPenalty - fuelBurnOffGain;

end

function [bestPitLap, bestRaceTime, raceTimesByPitLap, bestLapTimes] = optimizeOneStopStrategy(firstCompound, secondCompound, race, pitWindow)

    raceTimesByPitLap = zeros(size(pitWindow));
    lapTimeMatrix = zeros(length(pitWindow), race.laps);

    for i = 1:length(pitWindow)

        pitLap = pitWindow(i);
        lapTimes = zeros(1, race.laps);

        for lap = 1:race.laps

            raceLap = lap - 1;

            if lap <= pitLap
                tyreAge = lap - 1;
                lapTimes(lap) = calculateLapTime(firstCompound, tyreAge, raceLap, race);
            else
                tyreAge = lap - pitLap - 1;
                lapTimes(lap) = calculateLapTime(secondCompound, tyreAge, raceLap, race);
            end

        end

        % Add pit stop loss to the pit lap
        lapTimes(pitLap) = lapTimes(pitLap) + race.pitLoss;

        raceTimesByPitLap(i) = sum(lapTimes);
        lapTimeMatrix(i,:) = lapTimes;

    end

    [bestRaceTime, bestIndex] = min(raceTimesByPitLap);
    bestPitLap = pitWindow(bestIndex);
    bestLapTimes = lapTimeMatrix(bestIndex,:);

end