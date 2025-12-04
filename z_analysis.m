%% Event study
% On the effect of the election of Trump on stock returns in 2024
clear; close all; clc;

%% Load and merge data
ret=load('Preprocessed data\returns.mat').returns;
poll=load('Preprocessed data\polls_smooth.mat').pollData;

allData=outerjoin(poll,ret,'Keys','Date','Type','right','MergeKeys',true);

%% Preprocess
% Filter dates
allDataFiltered=allData((allData.Date>=datetime(2023,8,1))&(allData.Date<=datetime(2024,12,31)),:);

% Fill/drop NaN
allDataFiltered.TrumpLead=fillmissing(allDataFiltered.TrumpLead,'previous');
allDataFiltered.IsHarris=fillmissing(allDataFiltered.IsHarris,'previous');
allDataFiltered=allDataFiltered(~isnan(allDataFiltered.SP500),:);
allDataFiltered=movevars(allDataFiltered,'SP500','After','Date');
allDataFiltered=removevars(allDataFiltered,'IsHarris');
eventDay=datetime(2024,11,5); % Specify event date and window
eventIdx=find(allDataFiltered.Date==eventDay,1);
eventStart=eventIdx-2;
eventEnd=eventIdx+5;
eventWindowL=eventEnd-eventStart+1;
T=120; % Length of the estimation window
estimEnd=eventStart-30;
estimStart=estimEnd-T+1;

%% Regression
X=[ones(T,1),table2array(allDataFiltered(estimStart:estimEnd,2:3))]; % add col 2 back
Y=table2array(allDataFiltered(estimStart:estimEnd,4:end));
Betahat=(X'*X)\(X'*Y);
n=size(X,2);
m=size(Y,2);
epshat=Y-X*Betahat;
Sigmahat=(epshat'*epshat)./(T-n);
CovBetahat=kron(Sigmahat,inv(X'*X));
seBetahat=reshape(sqrt(diag(CovBetahat)),n,m);

%% Prediction and abnormal returns
Xpred=[ones(eventWindowL,1),table2array(allDataFiltered(eventStart:eventEnd,2:3))];  % add col 2 back
Ytrue=table2array(allDataFiltered(eventStart:eventEnd,4:end));
AR=Ytrue-Xpred*Betahat
CAR=sum(AR)
AAR=mean(AR,2);
CAAR=mean(CAR,2);

%% T stats
CovAR=kron(eye(eventWindowL),Sigmahat)+kron(Xpred/(X'*X)*Xpred',Sigmahat);
CovDiagAR=diag(CovAR);
seAR=NaN(eventWindowL,m);
for t=1:eventWindowL
    for k=1:m
        seAR(t,k)=sqrt(CovDiagAR(t+(k-1)*eventWindowL));
    end
end

% Calculate the t-statistics for the average abnormal returns
tStatAR=AR./seAR
pValAR=2*tcdf(tStatAR,T-n,'upper')

CovCAR=eventWindowL*Sigmahat+kron((Xpred'*ones(eventWindowL,1))'/(X'*X)*(Xpred'*ones(eventWindowL,1)),Sigmahat);
seCAR=sqrt(diag(CovCAR)');

% Calculate the t-statistics for the cumulated average abnormal returns
tStatCAR=CAR./seCAR
pValCAR=2*tcdf(abs(tStatCAR),T-n,'upper')

%% Tables
colNames=allDataFiltered.Properties.VariableNames(4:end);
eventDays={'t-2';'t-1';'t';'t+1';'t+2';'t+3';'t+4';'t+5'};

AR_tab=array2table(AR,'VariableNames',colNames);
AR_tab=addvars(AR_tab,eventDays,'NewVariableNames','t');
tStatAR_tab=array2table(tStatAR,'VariableNames',colNames);
tStatAR_tab=addvars(tStatAR_tab,eventDays,'NewVariableNames','t');
pValAR_tab=array2table(pValAR,'VariableNames',colNames);
pValAR_tab=addvars(pValAR_tab,eventDays,'NewVariableNames','t');

CAR_tab=array2table(CAR,'VariableNames',colNames);
tStatCAR_tab=array2table(tStatCAR,'VariableNames',colNames);
pValCAR_tab=array2table(pValCAR,'VariableNames',colNames);

writetable(AR_tab,'output.xlsx','Sheet','AR');
writetable(tStatAR_tab,'output.xlsx','Sheet','tStatAR');
writetable(pValAR_tab,'output.xlsx','Sheet','pValAR');

writetable(CAR_tab,'output.xlsx','Sheet','CAR');
writetable(tStatCAR_tab,'output.xlsx','Sheet','tStatCAR');
writetable(pValCAR_tab,'output.xlsx','Sheet','pValCAR');
