function[xOut,dateOut]=zf_01_kalman(data,name,Qmult)
    N=size(data.date,1);
    date=data.date; % Dates
    allDates=date(1):date(end);
    T=size(allDates,2);
    y=[NaN(1,2);data{:,{'Trump_R_',[name,'_D_']}}]'; % Poll data
    moe=data.moe; % Margin of error
    R=NaN(2,2,N+1); % R covariance matrix
    for i=1:N
        R(:,:,i+1)=[moe(i)^2 0;0 moe(i)^2];
    end
    q=(moe'*moe)/N; % Q covariance matrix
    Q=Qmult*q*eye(2);
    x0=[40;40]; % Initial x and P
    p=(x0(1)*x0(2));
    P0=[p 0;0 p];

    x=NaN(2,N+1); % Empty values
    x(:,1)=x0;
    P=NaN(2,2,N+1);
    P(:,:,1)=P0;

    i=2;
    for t=1:T
        today=allDates(t);

        % Prediction step
        xs=x(:,i-1); % State prediction
        Ps=P(:,:,i-1)+Q; % Covariance prediction

        while date(i)==today
            % Measurement update step
            v=y(:,i)-xs; % Measurement residual
            S=Ps+R(:,:,i); % Residual covariance
            K=Ps/S; % Kalman gain
            xs=xs+K*v; % State update
            Ps=(eye(2)-K)*Ps; % Covariance update

            i=i+1; % Update counter
            if i>N
                break;
            end
        end

        x(:,i-1)=xs;
        P(:,:,i-1)=Ps;
    end

    x=fillmissing(x,'next',2);

    x2=NaN(2,T); % Smoothed data for all days
    for t=1:length(allDates)
        idx=find(date == allDates(t), 1, 'first'); % First occurence
        if ~isempty(idx) % If date found
            x2(:,t)=x(:,idx); % Add value
        end
    end
    x2=fillmissing(x2,'previous',2);
    start_idx=(find(x2~=x2(:,1),1,'first')+1)/2; % Get column id for simple id
    xOut=x2(:,start_idx:end);
    dateOut=allDates(:,start_idx:end);
end
