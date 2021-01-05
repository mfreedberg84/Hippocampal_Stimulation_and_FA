clear;clc
disp('--------------- Starting DTI Analysis ------------------');
%% Analyze DTI data. Data include two groups: IPC (n = 24) and Vertex (n=11). 
% 12 IPC and 11 Vertex subjects have behavioral change data one day (Post) and one week (Follow-up) after stimulation. 
% All subjects have rsFC change data and baseline DTI FA data for the IPC-Parahippocampal (Tract1) 
% Parahippocampal-Entorhinal (Tract2), Entorhinal-Hippocampal (Tract3), IPC-Hippocampal (Tract4), and 
% IPC-Precuneus pathways (Tract5). Run this script in the same folder as
% the "Hippoampal_Enhancement_and_FA_Data.csv" file. You must specify a
% drive to locate the "corr_rtest.m" downloaded function. NaNs in data file
% represent either outlier data or a failure to trace that tract.
% Add matlab toolbox drive
MTLAB_dir = '';
addpath(MTLAB_dir);
%Number of simulations for each permutation test
Sims = 50000;
% Spearman or Pearson
CorrType = 'Spearman';
disp('***** Starting variables loaded ****');
%% Load in data
DTI_Data = csvread('Hippocampal_Enhancement_and_FA_Data.csv');
% Organization of data file:
% Column 1: Group (1 = IPC, 2 = Vertex)
% Column 2: Participant Number
% Column 3: Hippocampal-Precuneus rsFC change data 
% Column 4: Tract1 FA (IPC-Parahippocampal)
% Column 5: Tract2 FA (Parahippocampal-Entorhinal)
% Column 6: Tract3 FA (Entorhinal-Hippocampal)
% Column 7: Tract5 FA (IPC-Hippocampal)
% Column 8: Tract6 FA (IPC-Precuneus)
% Column 9: Tract7 FA (IPC-Precentral; Control Tract)
% Column 10: Changes in episodic memory (1 day after stimulation)
% Column 11: Changes in episodic memory (1 week after stimulation)
% Column 12: Changes in procedural memory (1 day after stimulation)
% Column 13: changes in procedural memory (1 week after stimulation)

% Isolate Tracks Data
Tract_Data = DTI_Data(:,[4:8]);
Outcome_Data = [DTI_Data(:,3) DTI_Data(:,[10:13])];
disp('***** Data loaded ****');
%% Track Analysis 
Tracts = {'Tract1', 'Tract2', 'Tract3', 'Tract4', 'Tract5'};
Outcomes = {'RSFC', 'Episodic_1day', 'Episodic_1week', 'Procedural_1day','Procedural_1week'};
for k=1:length(Tracts)
    for l=1:length(Outcomes)
        disp(' --- ');
        disp(' --- ');
        disp(' --- ');
        disp(['Performing ' table2array(Tracts(1,k)) '-' table2array(Outcomes(1,l)) ' analyses...']);
        % Create table with group, k'th tract, and l'th outcome (rsFC or memory)
        Data_Table = [DTI_Data(:,1) Tract_Data(:,k) Outcome_Data(:,l)];
        % Eliminate NaNs related to bad tracts
        Tract_Cut = Data_Table(~isnan(Data_Table(:,2)),:);
        % Get rid of Outcome NaNs
        Outcome_and_Tract_Cut = Tract_Cut(~isnan(Tract_Cut(:,3)),:);
        % Isolate data for each group (1 = IPC, 2 = Vertex)
        Good_data_IPC = Outcome_and_Tract_Cut(Outcome_and_Tract_Cut(:,1) == 1, :);
        Good_data_Vertex = Outcome_and_Tract_Cut(Outcome_and_Tract_Cut(:,1) == 2, :);
        % Calculate degrees of freedom for both groups
        dof_IPC = length(Good_data_IPC)-2;
        dof_Vertex = length(Good_data_Vertex)-2;
        % Calculate correlation for IPC group
        [Rho_IPC IPC_p] = corr(Good_data_IPC(:,2), Good_data_IPC(:,3),'Type',CorrType);
        % Spearman correlation for Vertex
        [Rho_Vertex Vertex_p] = corr(Good_data_Vertex(:,2), Good_data_Vertex(:,3),'Type',CorrType);
        % Contrast correlations between groups
        [p, zobs, za, zb] = corr_rtest(Rho_IPC, Rho_Vertex, length(Good_data_IPC), length(Good_data_Vertex));
        Rho_Diff_obs = za-zb;
        disp(' ---- Correlations and contrast ---- ');
        disp(['IPC Correlation: r(' num2str(dof_IPC) ')= ' num2str(Rho_IPC) ', p = ' num2str(IPC_p)]);
        disp(['Vertex Correlation: r(' num2str(dof_Vertex) ')= ' num2str(Rho_Vertex) ', p = ' num2str(Vertex_p)]);
        disp(['Observed difference between z(r) values is ' num2str(Rho_Diff_obs)]);
        % Make distribution of Z-statistic values 
        disp(' ---- Making distribution of z values ---- ');
        for i=1:Sims
            % Shuffle group labels 
            Shuffle = randperm(length(Outcome_and_Tract_Cut));
            NumbIPC = length(Good_data_IPC);
            NumbVertex = length(Good_data_Vertex);
            for j=1:length(Outcome_and_Tract_Cut)
                if j<=NumbIPC; Perm_Data(j,1)=1;else;Perm_Data(j,1)=2;end
                Perm_Data(j,[2:3]) = Outcome_and_Tract_Cut(Shuffle(1,j),[2:3]);
            end   
            % Isolate data for each group
            Perm_IPC = Perm_Data(Perm_Data(:,1) == 1, [2:3]);
            Perm_Vertex = Perm_Data(Perm_Data(:,1) == 2, [2:3]);
            % Count number of participants in each group
            NumbIPC = length(Perm_IPC);
            NumbVertex = length(Perm_Vertex);
            % Spearman correlation for IPC
            [Rho_IPC IPC_p] = corr(Perm_IPC(:,1), Perm_IPC(:,2),'Type',CorrType);
            % Spearman correlation for Vertex
            [Rho_Vertex Vertex_p] = corr(Perm_Vertex(:,1), Perm_Vertex(:,2),'Type',CorrType);
            % Contrast correlations
            [p, z, za, zb] = corr_rtest(Rho_IPC, Rho_Vertex, NumbIPC, NumbVertex);
            % Calculate difference in Rhos between correlations
            Rho_Diff = za-zb;
            % Add to the distribution of values.
            Distribution_Value(i) = Rho_Diff;
            clear Shuffle Perm_Data Perm_IPC Perm_Vertex p z za zb Rho_Diff Perm_Tract_Cut Perm_Out_Cut
        end
        % Create histogram of distribution values. The red line is the Zobs
        % value
        %hist(Distribution_Value,100);
        %hold on;
        %line([Rho_Diff_obs, Rho_Diff_obs],ylim, 'LineWidth', 2, 'Color', 'r');
        % Calculate the percentage of distrubution values greater than the
        % Zobs value.
        Permp = sum(Distribution_Value>Rho_Diff_obs)/Sims;
        if Rho_Diff_obs<prctile(Distribution_Value, 95); disp(' x x x No Group Differences x x x '); else; disp(' x x x SIGNIFICANT GROUP DIFFERENCE!!! x x x '); end
        disp(['Observed difference is ' num2str(Rho_Diff_obs) ' and upper 5% starts at ' num2str(prctile(Distribution_Value,95)) ', p = ' num2str(Permp)]);
        %pause;
        %close;
        % Record essential information.
        WO_Tables(k).matrix(l,[1:5]) = [k,l, Rho_Diff_obs, prctile(Distribution_Value,95), Permp];
    end
    clear Data_Table Tract_Cut Outcome_and_Tract_Cut Good_data_IPC Good_data_Vertex p z za zb Rho_Diff dof_IPC dof_Vertex Rho_IPC Rho_Vertex IPC_p Vertex_p zobs za zb
end
Final_Table = [WO_Tables(1).matrix; WO_Tables(2).matrix; WO_Tables(3).matrix; WO_Tables(4).matrix; WO_Tables(5).matrix];
save('Stimulation_Effects.txt', 'Final_Table', '-ascii');
%% End program
disp('xxxxxxxxxxxxxxxxxxxx');
disp('Finished Permuations');
disp('xxxxxxxxxxxxxxxxxxxx');
