%% Event study
% On the effect of the election of Trump on stock returns in 2024
clear; close all; clc;

%% Load and merge data
ret=load('Preprocessed data/returns.mat').returns;
poll=load('Preprocessed data/polls_smooth.mat').pollData;
fac=load('Preprocessed data/ff_factors.mat').fac;

all_data=outerjoin(poll,ret,'Keys','Date','Type','right','MergeKeys',true);
all_data=outerjoin(all_data,fac,'Keys','Date','Type','left','MergeKeys',true);

%% Preprocess
% Filter dates
all_data_filtered=all_data((all_data.Date>=datetime(2023,8,1))&(all_data.Date<=datetime(2024,12,31)),:);

% Fill/drop NaN
all_data_filtered.TrumpLead=fillmissing(all_data_filtered.TrumpLead,'previous');
all_data_filtered.IsHarris=fillmissing(all_data_filtered.IsHarris,'previous');
all_data_filtered=all_data_filtered(~isnan(all_data_filtered.SP500),:);
all_data_filtered=movevars(all_data_filtered,'HML','After','Date');
all_data_filtered=movevars(all_data_filtered,'SMB','After','Date');
all_data_filtered=movevars(all_data_filtered,'Mkt_RF','After','Date');
all_data_filtered=movevars(all_data_filtered,'RF','After','Date');
all_data_filtered=movevars(all_data_filtered,'SP500','After','Date');
%all_data_filtered=removevars(all_data_filtered,'IsHarris');
event_day=datetime(2024,11,5); % Specify event date and window
event_idx=find(all_data_filtered.Date==event_day,1);
event_start=event_idx-2;
event_end=event_idx+5;
event_window_l=event_end-event_start+1;
T=120; % Length of the estimation window
puffer_days=30;
estim_end=event_start-puffer_days;
estim_start=estim_end-T+1;

%% Regression
X=[ones(T,1),table2array(all_data_filtered(estim_start:estim_end,4:7))]; % add col 2 back
Y=table2array(all_data_filtered(estim_start:estim_end,9:end));
Beta_hat = X\Y  % helyett: (X'*X)\(X'*Y)
n=size(X,2);
m=size(Y,2);
eps_hat=Y-X*Beta_hat;
Sigma_hat=(eps_hat'*eps_hat)./(T-n);
Cov_Beta_hat=kron(Sigma_hat,inv(X'*X));
se_Beta_hat=reshape(sqrt(diag(Cov_Beta_hat)),n,m)

%% Prediction and abnormal returns
X_pred=[ones(event_window_l,1),table2array(all_data_filtered(event_start:event_end,4:7))];  % add col 2 back
Y_true=table2array(all_data_filtered(event_start:event_end,9:end));
AR=Y_true-X_pred*Beta_hat;
CAR_all=cumsum(AR);
CAR=sum(AR(4:end,:));
AAR=mean(AR,2);
CAAR_all=mean(CAR_all,2);
CAAR=mean(CAR,2);

%% Separately by favorable candidate
support_stocks=readtable('candidate_stocks.xlsx','Sheet','stocks');
support_sectors=readtable('candidate_stocks.xlsx','Sheet','sectors');
[~,support_stocks_trump]=ismember(support_stocks.Trump(~ismissing(support_stocks.Trump)),all_data_filtered.Properties.VariableNames);
[~,support_stocks_harris]=ismember(support_stocks.Harris(~ismissing(support_stocks.Harris)),all_data_filtered.Properties.VariableNames);
[~,support_sectors_trump]=ismember(support_sectors.Trump(~ismissing(support_sectors.Trump)),all_data_filtered.Properties.VariableNames);
[~,support_sectors_harris]=ismember(support_sectors.Harris(~ismissing(support_sectors.Harris)),all_data_filtered.Properties.VariableNames);

AR_stocks_trump=AR(:,support_stocks_trump-8); % Abnormal stock & sector returns
AR_stocks_harris=AR(:,support_stocks_harris-8);
AR_sectors_trump=AR(:,support_sectors_trump-8);
AR_sectors_harris=AR(:,support_sectors_harris-8);

CAR_stocks_trump=sum(AR(4:end,support_stocks_trump-8)); % Cumulated abnormal returns t+1 - t+5
CAR_stocks_harris=sum(AR(4:end,support_stocks_harris-8));
CAR_sectors_trump=sum(AR(4:end,support_sectors_trump-8));
CAR_sectors_harris=sum(AR(4:end,support_sectors_harris-8));

AAR_stocks_trump=mean(AR_stocks_trump,2);
AAR_stocks_harris=mean(AR_stocks_harris,2);
AAR_sectors_trump=mean(AR_sectors_trump,2);
AAR_sectors_harris=mean(AR_sectors_harris,2);

%% T stats
C=1+trace(X/(X'*X)*X')/T; % Correction term
Cov_AR=Sigma_hat*C;
se_AR=sqrt(diag(Cov_AR)');

% Calculate the t-statistics for the average abnormal returns
t_stat_AR=AR./se_AR;
p_val_AR=2*tcdf(abs(t_stat_AR),T-n,'upper');

%CovCAR=eventWindowL*Sigmahat+kron((Xpred'*ones(eventWindowL,1))'/(X'*X)*(Xpred'*ones(eventWindowL,1)),Sigmahat);
se_CAR=sqrt(sum(se_AR.^2));

% Calculate the t-statistics for the cumulated average abnormal returns
t_stat_CAR=CAR./se_CAR;
p_val_CAR=2*tcdf(abs(t_stat_CAR),T-n,'upper');

%% T stats by candidate
% Stocks Trump
eps_hat_stocks_trump=eps_hat(:,support_stocks_trump-8);
Sigma_hat_stocks_trump=(eps_hat_stocks_trump'*eps_hat_stocks_trump)./(T-n);
Cov_AR_stocks_trump=Sigma_hat_stocks_trump*C;
se_AR_stocks_trump=sqrt(diag(Cov_AR_stocks_trump)');

t_stat_AR_stocks_trump=AR_stocks_trump./se_AR_stocks_trump
p_val_AR_stocks_trump=2*tcdf(abs(t_stat_AR_stocks_trump),T-n,'upper')

% Stocks Harris
eps_hat_stocks_harris=eps_hat(:,support_stocks_harris-8);
Sigma_hat_stocks_harris=(eps_hat_stocks_harris'*eps_hat_stocks_harris)./(T-n);
Cov_AR_stocks_harris=Sigma_hat_stocks_harris*C;
se_AR_stocks_harris=sqrt(diag(Cov_AR_stocks_harris)');

t_stat_AR_stocks_harris=AR_stocks_harris./se_AR_stocks_harris
p_val_AR_stocks_harris=2*tcdf(abs(t_stat_AR_stocks_harris),T-n,'upper')



% Sectors Trump
eps_hat_sectors_trump=eps_hat(:,support_sectors_trump-8);
Sigma_hat_sectors_trump=(eps_hat_sectors_trump'*eps_hat_sectors_trump)./(T-n);
Cov_AR_sectors_trump=Sigma_hat_sectors_trump*C;
se_AR_sectors_trump=sqrt(diag(Cov_AR_sectors_trump)');

t_stat_AR_sectors_trump=AR_sectors_trump./se_AR_sectors_trump;
p_val_AR_sectors_trump=2*tcdf(abs(t_stat_AR_sectors_trump),T-n,'upper');

% Sectors Harris
eps_hat_sectors_harris=eps_hat(:,support_sectors_harris-8);
Sigma_hat_sectors_harris=(eps_hat_sectors_harris'*eps_hat_sectors_harris)./(T-n);
Cov_AR_sectors_harris=Sigma_hat_sectors_harris*C;
se_AR_sectors_harris=sqrt(diag(Cov_AR_sectors_harris)');

t_stat_AR_sectors_harris=AR_sectors_harris./se_AR_sectors_harris;
p_val_AR_sectors_harris=2*tcdf(abs(t_stat_AR_sectors_harris),T-n,'upper');

%% Tables
col_names=all_data_filtered.Properties.VariableNames(9:end);
event_days={'t-2';'t-1';'t';'t+1';'t+2';'t+3';'t+4';'t+5'};

AR_tab=array2table(AR,'VariableNames',col_names);
AR_tab=addvars(AR_tab,event_days,'NewVariableNames','t');
t_stat_AR_tab=array2table(t_stat_AR,'VariableNames',col_names);
t_stat_AR_tab=addvars(t_stat_AR_tab,event_days,'NewVariableNames','t');
p_val_AR_tab=array2table(p_val_AR,'VariableNames',col_names);
p_val_AR_tab=addvars(p_val_AR_tab,event_days,'NewVariableNames','t');

CAR_tab=array2table(CAR,'VariableNames',col_names);
t_stat_CAR_tab=array2table(t_stat_CAR,'VariableNames',col_names);
p_val_CAR_tab=array2table(p_val_CAR,'VariableNames',col_names);

writetable(AR_tab,'output.xlsx','Sheet','AR');
writetable(t_stat_AR_tab,'output.xlsx','Sheet','tStatAR');
writetable(p_val_AR_tab,'output.xlsx','Sheet','pValAR');

writetable(CAR_tab,'output.xlsx','Sheet','CAR');
writetable(t_stat_CAR_tab,'output.xlsx','Sheet','tStatCAR');
writetable(p_val_CAR_tab,'output.xlsx','Sheet','pValCAR');

%% Ábrák
se_AAR=ones(event_window_l,1)*sqrt(mean(se_AR.^2));
se_CAAR=sqrt(cumsum(se_AAR.^2));

se_AAR_stocks_trump=ones(event_window_l,1)*sqrt(mean(se_AR_stocks_trump.^2));
se_AAR_stocks_harris=ones(event_window_l,1)*sqrt(mean(se_AR_stocks_harris.^2));

se_CAAR_stocks_trump=sqrt(cumsum(se_AAR_stocks_trump));
se_CAAR_stocks_harris=sqrt(cumsum(se_AAR_stocks_harris));

% Abnormális hozamok
figure;
h1=plot(-2:5,AR,'Color',[0.7 0.7 0.7],'LineWidth',1);
hold on;
h2=plot(-2:5,AAR,'k-','LineWidth',2);
fill([-2:5,fliplr(-2:5)],[AAR'+1.96*se_AAR',fliplr(AAR'-1.96*se_AAR')],'r','FaceAlpha',0.1,'EdgeColor','none');
xlabel('Napok az eseményhez képest');
ylabel('Abnormális hozamok');
title('Abnormális hozamok az eseménynap körül');
legend([h1(1),h2],'AR','AAR')
xline(0,'r--','LineWidth',1,'HandleVisibility','off');
yline(0,'k-','LineWidth',0.5,'HandleVisibility','off');
grid on;

% Kumulált abnormális hozamok
figure;
h1=plot(-2:5,CAR_all,'Color',[0.7 0.7 0.7],'LineWidth',1);
hold on;
fill([-2:5,fliplr(-2:5)],[CAAR_all'+1.96*se_CAAR',fliplr(CAAR_all'-1.96*se_CAAR')],'r','FaceAlpha',0.1,'EdgeColor','none');
h2=plot(-2:5,CAAR_all,'k-','LineWidth',2);
xlabel('Napok az eseményhez képest');
ylabel('Kumulált abnormális hozamok');
title('Kumulált abnormális hozamok az eseménynap körül');
legend([h1(1),h2],'CAR','CAAR');
xline(0,'r--','LineWidth',1,'HandleVisibility','off');
yline(0,'k-','LineWidth',0.5,'HandleVisibility','off');
grid on;

% AR Trump
figure;
h1=plot(-2:5,AR_stocks_trump,'Color',[0.7 0.7 0.7],'LineWidth',1);
hold on;
h2=plot(-2:5,AAR_stocks_trump,'k-','LineWidth',2);
fill([-2:5,fliplr(-2:5)],[AAR_stocks_trump'+1.96*se_AAR_stocks_trump',fliplr(AAR_stocks_trump'-1.96*se_AAR_stocks_trump')],'r','FaceAlpha',0.1,'EdgeColor','none');
xlabel('Napok az eseményhez képest');
ylabel('Abnormális hozamok');
title('Abnormális hozamok az eseménynap körül');
legend([h1(1),h2],'AR','AAR')
xline(0,'r--','LineWidth',1,'HandleVisibility','off');
yline(0,'k-','LineWidth',0.5,'HandleVisibility','off');
grid on;

