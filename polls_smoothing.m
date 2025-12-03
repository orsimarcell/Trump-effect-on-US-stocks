%% Preprocessing US polling data
clear; close all; clc

%% Load raw data
%dataBiden=readtable('Raw data\polls.xlsx','Sheet','TrumpVBiden');
%dataHarris=readtable('Raw data\polls.xlsx','Sheet','TrumpVHarris');
%save('Raw data\polls.mat');

load('Raw data\polls.mat');

%% Preprocess data
dataBiden=preprocess(dataBiden);
dataHarris=preprocess(dataHarris);
dataBiden.moe=updateMOE(dataBiden.sample,dataBiden.moe);
dataHarris.moe=updateMOE(dataHarris.sample,dataHarris.moe);

%% Kalman filter
q=0.001;
[xB,dateB]=kalman(dataBiden,'Biden',q);
[xH,dateH]=kalman(dataHarris,'Harris',q);

figure;
hold on;
plot(dateB,xB(1,:),'r')
plot(dateB,xB(2,:),'b')
hold off;

figure;
hold on;
plot(dateH,xH(1,:),'r')
plot(dateH,xH(2,:),'b')
hold off;

%% Data table
biden_withdrawal=datetime(2024,7,21); % Important dates
election_day=datetime(2024,11,5);

startB=1; % Dates when Biden was Democrat candidate
endB=find(dateB==biden_withdrawal,1)-1;

startH=find(dateH==biden_withdrawal,1); % Dates when Harris was Democrat candidate
endH=find(dateH==election_day-days(1),1);

datamat=[xB(:,startB:endB)',zeros(endB-startB+1,1); % All data excluding dates
         xH(:,startH:endH)',ones(endH-startH+1,1)];

pollData=array2table(datamat,'VariableNames',{'Republican','Democrat','AfterWithdrawal'});
pollData.Date=(dateB(startB):dateH(endH))';
pollData=movevars(pollData,'Date','Before',1);

save('Preprocessed data\polls_smooth.mat','pollData');
