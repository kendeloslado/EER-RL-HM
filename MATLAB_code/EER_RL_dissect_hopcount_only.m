%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              EER-RL                                  %
%       Energy-Efficient Routing based on Reinforcement Learning       %        
%                      Mobile Information Systems                      %
%                           Research Article                           %
%                                                                      %
% (c) Vially KAZADI MUTOMBO, PhD Candidate                             %
% Soongsil University                                                  %
% Department of Computer Science                                       %
% mutombo.kazadi@gmail.com                                             %
% February 2021                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;
clear;
clc;
%%
%%%%%%%%%%%%%%%%%%%%%% Beginning  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% Network Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Sensing Field Dimensions in meters %
xm=100;
ym=100;
x=0; % added for better display results of the plot
y=0; % added for better display results of the plot
% Number of Nodes in the field %
n=100;
% Number of Dead Nodes in the beggining %
dead_nodes=0;
% Coordinates of the Sink (location is predetermined in this simulation) %
sinkx=50;
sinky=50;

%%% Energy parameters %%%
% Energy required to run circuity (both for transmitter and receiver) %
Eelec=50*10^(-9); % units in Joules/bit
ETx=50*10^(-9); % units in Joules/bit
ERx=50*10^(-9); % units in Joules/bit
% Transmit Amplifier Types %
Eamp=100*10^(-12); % units in Joules/bit/m^2 (amount of energy spent by the amplifier to transmit the bits)
% Data Aggregation Energy %
EDA=5*10^(-9); % units in Joules/bit
% Size of data package %
k=4000; % units in bits 
% Round of Operation %
rnd=0;
tot_rnd=15000;
% Current Number of operating Nodes %
op_nodes=n; %Operating nodes
transmissions=0;
d(n,n)=0;
source=1;
flag1stdead=0;
range_C = 15; %Transmission range
alpha=1; %Learning Rate
gamma = 0.95; % Discount Factor
p=0.5 % Energy's Probabilistic parameter 
q1=1-p % Hop count probabilistic parameter

CH_tot= ceil(n*0.1);
%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Network settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%% WSN Creation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting the WSN %
load('fixedseed.mat', 'NET')
for i=1:n
    
     
%     NET(i).id=i;	% sensor's ID number
%     NET(i).x=rand(1,1)*xm;	% X-axis coordinates of sensor node
%     NET(i).y=rand(1,1)*ym;	% Y-axis coordinates of sensor node
%     %NET(i).E=Eo;     % nodes energy levels (initially set to be equal to "Eo
%     NET(i).E = randi([1,2]); % For heterogeneous WNET
%     NET(i).Eo = NET(i).E;
%     NET(i).cond=1;   % States the current condition of the node. when the node is operational its value is =1 and when dead =0
%     %NET(i).dts=0;    % nodes distance from the sink
%     NET(i).dts= sqrt((sinkx-NET(i).x)^2 + (sinky-NET(i).y)^2);
%     NET(i).hop=ceil(NET(i).dts/range_C); %Hop count estimate to the sink
%     NET(i).role=0;   % node acts as normal if the value is '0', if elected as a cluster head it  gets the value '1' (initially all nodes are normal)
%     %NET(i).pos=0;
%     %NET(i).first=0;  %Initial route available. If it the first time a node send a packet its value is 0, otherwise it's 1
%     NET(i).closest=0;
%     NET(i).prev=0;
%     %NET(i).next=0;
%     %NET(i).dis=0;	% distance between two nodes headin towards to the cluster head from position 1
%     NET(i).sel=0;    % states if the node has already operated for this round or not (if 0 then no, if 1 then yes) 
%     NET(i).rop=0;    % number of rounds node was operational
%     NET(i).dest=0;
%     NET(i).dts_ch=0;
%     NET(i).hops_ch=0;
%     %order(i)=0;

    hold on;
    figure(1);
    plot(x,y,xm,ym,NET(i).x,NET(i).y,'ob','DisplayName','cm');
    plot(x,y,xm,ym,sinkx,sinky,'*r','DisplayName','sink');
    title 'EER-RL';
    xlabel '(m)';
    ylabel '(m)';
end

% find Neighbor nodes
%Compute Q-Value
min_E = min([NET.E]); 
max_E = max([NET.E]); % piggy back from HB pkt
for i=1:n
    if(min_E ==max_E)
        Q(i) = 1 / NET(i).hop;
        NET(i).Q = Q(i);
    else
        Q(i) = (p*(NET(i).E - min_E)/(max_E-min_E)+(q1/NET(i).hop));
        NET(i).Q = Q(i);
        %CH = maxk(Q,10); %Find 10 strongest nodes 
    end
end
%%
%------------------- BEGINNING OF CLUSTERING -----------------------------
%CLUSTER HEAD ELECTION
for i=1:n
   CM(i) = NET(i); %Make a copy of the network
end
tot = 1;

while(tot<=CH_tot)
    for i=1:n
        %maxx= max([CM.Q]);
        %disp(maxx);
        if(CM(i).Q == max([CM.Q])) 
        % filter nodes with highest Q-value
            if tot == 1 && CM(i).hop>=2 && CM(i).hop<=3
            % this conditional's for searching the first cluster head
            % pick node whose distance to sink (dts) is between 15-50
                CH(tot) = CM(i);
                % elect as a cluster head
                NET(i).role=1;
                % set "role" flag to 1 in the NET struct 
                plot(x,y,xm,ym,NET(i).x,NET(i).y,'Or','DisplayName','CH');
                % color this cluster head as red
                CM(i).Q = 0;
                tot =tot+1;
            % elseif tot>1 &&  CM(i).dts>=15 && CM(i).dts<=50
            elseif tot>1 &&  CM(i).hop>=2 && CM(i).hop<=3
                cl = 0;
                for t = 1:length(CH)
                    dts = sqrt((CM(i).x-CH(t).x)^2 + (CM(i).y-CH(t).y)^2);
                    hop=ceil(dts/range_C);
                    %if(dts <=15)
                    if(CM(i).hop <=1)
                    % do not elect as cluster head flag
                        cl=cl +1;
                        break;
                    end
                end
                if cl==0
                    CH(tot) = CM(i);
                    % elect as cluster head
    
                    plot(x,y,xm,ym,NET(i).x,NET(i).y,'Or');
                    
                    NET(i).role=1;
                    CM(i).Q = 0;
                    tot =tot+1;  
                else
                    CM(i).Q = 0;
                end
            else
                CM(i).Q = 0;
            end
                
        end
           if tot >CH_tot
               break;
           end
    end
end
%END CLUSTER HEAD ELECTION
%%
%CLUSTER FORMATION
for i=1:n
    for ch=1:CH_tot
        dts_ch(i,ch) = sqrt((NET(i).x-CH(ch).x)^2 + (NET(i).y-CH(ch).y)^2);
        hops_ch(i,ch) = ceil(dts_ch(i,ch)/range_C);
        dts_ch(dts_ch==0)=NaN;
        % if cluster recipient is itself, put NaN to avoid self-feedback or
        % something
    end
    if NET(i).hop<=1
        NET(i).dest = 0;
        NET(i).dts_ch = 0;
        % no need to form clusters if you're within base station range
        figure(1);
        plot([NET(i).x sinkx], [NET(i).y sinky], '-g', 'DisplayName', 'Tx');
    else
        if NET(i).role==0
            for ch = 1:CH_tot
                dtsCh = sqrt((NET(i).x-CH(ch).x)^2 + (NET(i).y-CH(ch).y)^2);
                hopsCh = ceil(dtsCh/range_C);
%                 if NET(i).E>0 && dtsCh <= min([dts_ch(i,:)])
                if NET(i).E>0 && hopsCh <= min([hops_ch(i,:)])
                    NET(i).dest = CH(ch).id;
                    %NET(i).dts_ch = min([dts_ch(i,:)]);
                    NET(i).hops_ch = min([hops_ch(i,:)]);
                    figure(1);
                    plot([NET(i).x CH(ch).x], [NET(i).y CH(ch).y],'-c','DisplayName','Tx');
                    % draw another figure
                    %legend;
                    %hold off;
                    
                    break;
                end
            end
        end  
    end             
end
%END CLUSTER FORMATION
for i=1:CH_tot
    ncm=1;
    for j=1:n
        if(NET(j).dest == CH(i).id && NET(j).role==0)
            cluster(i,ncm)= NET(j);
            ncm= ncm+1;
        end
    end
end
%------------------- END OF CLUSTERING -----------------------------------


%%
%COMMUNICATION PHASE------------------------------------------------------
dead=0;
while(op_nodes>50 && rnd<tot_rnd)
    
    %Node nearby the Sink node
    ns=1;
    for l=1:n
        if NET(l).E>0
            if NET(l).hop<=1 && NET(l).role==0
                Next_sink(ns) = NET(l);
                % this seems to tell that nodes next to the sink is NET(l).
                % but... going through this sequentially would mean that
                % the next_sink will use the node with the highest id... is
                % this supposed to happen?
            end
        end    
    end
   
    for j = 1:CH_tot
        for ns=1:length(Next_sink)
            dts_tmp(j,ns) = sqrt((CH(j).x-Next_sink(ns).x)^2 + (CH(j).y-Next_sink(ns).y)^2);
            hop_tmp(j,ns) = ceil(dts_tmp(j,ns)/range_C);
            % get distance of node j to Next_sink(ns)
        end
    end
     %en Node nearby the sink
    energy=0;
    %INTRACLUSTER MULTIHOP COMMUNICATION
    % INTRA = within the cluster
    for i=1:CH_tot
    % there are 10 cluster heads
    % i represents cluster heads; while
    % j represents the cluster members
        ncm=1;
        for j =1:length(cluster(i,:))
        % length simply gets the number of members in a cluster formation
            if cluster(i,j).dest == CH(i).id
            % cluster member picks the cluster head as next hop (i think)
                if cluster(i,j).E>0
                % node should be alive
                    maxQ = max([cluster(i,:).Q]);
%                     if (cluster(i,j).dts_ch<=range_C || cluster(i,j).Q == maxQ)
                    if (cluster(i,j).hops_ch<=1 || cluster(i,j).Q == maxQ)
                    % cluster member must be within range OR cluster's
                    % the one with highest Q-value
                    % "devices with the highest Q-value in their 
                    % neighbourhood and devices with the base station in 
                    % their transmission range can communicate directly 
                    % with the base station without any intermediate
                    % device."
                        if cluster(i,j).prev==0
                        % cluster member has no received packets
                        % transmit packets only
%                             ETx= Eelec*k + Eamp*k*cluster(i,j).dts_ch^2;
                            ETx= Eelec*k + Eamp*k*cluster(i,j).hops_ch*range_C^2;
                            cluster(i,j).E = cluster(i,j).E-ETx;
                            NET(cluster(i,j).id).E=cluster(i,j).E;
                            energy=energy+ETx;
                            CH(i).prev = CH(i).prev +1;
                        else
                        % cluster member has received packets
                        % member has received and is transmitting packets
                            ERx=(EDA+Eelec)*k;
%                             ETx= Eelec*k + Eamp*k*cluster(i,j).dts_ch^2;
                            ETx= Eelec*k + Eamp*k*cluster(i,j).hops_ch*range_C^2;
                            NET(cluster(i,j).id).E=NET(cluster(i,j).id).E-ETx-ERx;
                            cluster(i,j).E = NET(cluster(i,j).id).E;
                            cluster(i,j).prev=0;
                            energy=energy+ETx+ERx;
                            CH(i).prev = CH(i).prev +1;
                        end
                        %Compute the reward
                        Q_old = cluster(i,j).Q;
                        R= (p*(cluster(i,j).E - min_E)/(max_E-min_E)+(q1/cluster(i,j).hop));
                        
                        %update Q_value
                        cluster(i,j).Q =Q_old + alpha*(R+ gamma * maxQ -Q_old) ;
                        NET(cluster(i,j).id).Q = cluster(i,j).Q;
                        
                    else
                    % cluster member is not within range of a CH nor is it 
                    % highest Q-value (maxQ)
                        for nex = 1:length(cluster(i,:))
                            if(cluster(i,nex).E>0)
                                if(cluster(i,nex).Q ==maxQ)
                                    next = cluster(i,nex);
                                    % pick cluster member node as next hop?
                                    % is this cluster head or is this the
                                    % node with the highest Q-value?
                                    cluster(i,nex).prev=1;
                                    nextID=nex;
                                    % take note of the ID
                                    break;
                                end
                            else
                                cluster(i,nex).Q = -100;
                                % dead node
                            end
                           
                        end
                        dts_cm = sqrt((next.x-cluster(i,j).x)^2 + (next.y-cluster(i,j).y)^2);
                        hops_cm = ceil(dts_cm/range_C);
                        % distance between next hop and cluster member
                        if cluster(i,j).prev==0
                        % cluster member has not received packets yet. this
                        % is a transmit packet-only case
%                             ETx= Eelec*k + Eamp*k*dts_cm^2;
                            ETx= Eelec*k + Eamp*k*(hops_cm*range_C)^2;
                            NET(cluster(i,j).id).E=NET(cluster(i,j).id).E-ETx;
                            cluster(i,j).E = cluster(i,j).E-ETx;
                            energy=energy+ETx;
                        else
                        % cluster member has received packets
                        % received and transmit packets
                            ERx=(EDA+Eelec)*k;
                            % ETx= Eelec*k + Eamp*k*dts_cm^2;
                            ETx= Eelec*k + Eamp*k*(hops_cm*range_C)^2;
                            NET(cluster(i,j).id).E=NET(cluster(i,j).id).E-ETx-ERx;
                            cluster(i,j).E = cluster(i,j).E-ETx-ERx;
                            cluster(i,j).prev=0;
                            energy=energy+ETx;
                        end
                        %Compute the reward
                        Q_old = cluster(i,j).Q;
                        R= (p*(cluster(i,j).E - min_E)/(max_E-min_E)+(q1/cluster(i,j).hop));
                        
                        %update Q_value
                        cluster(i,j).Q =Q_old + alpha*(R+ gamma * maxQ -Q_old) ;
                        NET(cluster(i,j).id).Q = cluster(i,j).Q;
                        
                        Q_old = NET(next.id).Q;
                        cluster(i,nextID).Q  =Q_old + alpha*(R+ gamma * maxQ -Q_old) ;
                        NET(cluster(i,nextID).id).Q = cluster(i,nextID).Q;
                    end
                
                else
                    cluster(i,j).Q = -100;
                end
                    
            end
        end
    end

    %END OF INTRACLUSTER MULTIHOP COMMUNICATION

    %INTERCLUSTER COMMUNICATION
    for j =1:CH_tot
        thres = NET(CH(j).id).Eo * 0.4;
        if CH(j).E >thres && thres>0
        % this threshold's here to control energy consumption I presume
        % this threshold's here to signal the network to recluster once it
        % is breached.
            if(CH(j).hop<=1)
            % cluster head's within range
                if CH(j).prev ==0
                % cluster head has no packets received
                % TRANSMIT ONLY
%                     ETx= Eelec*k + Eamp*k*CH(j).hop*range_C^2;
                    ETx= Eelec*k + Eamp*k*(CH(j).hop*range_C)^2;
                    NET(CH(j).id).E=NET(CH(j).id).E-ETx;
                    CH(j).E = CH(j).E-ETx;

                    energy=energy+ETx;
                else
                % cluster head has packets received
                % TRANSMIT AND RECEIVED PACKETS
                    %ERx=(EDA+Eelec)*k;
                    %ETx= Eelec*k + Eamp*k*CH(j).dts^2;
                    %Edis = (k*CH(j).prev*(Eelec + EDA) + k*(Eelec+Eamp*(CH(j).dts^2)));
                    Edis = (k*(Eelec + EDA) + k*(Eelec+Eamp*((CH(j).hop*range_C)^2)));
                    NET(CH(j).id).E=NET(CH(j).id).E-Edis;
                    % line above didn't have a semicolon, could be
                    % intentional.
                    CH(j).E = CH(j).E-Edis;
                    energy=energy+Edis;
                    CH(j).prev =0;
                end
                
            else
            % cluster head is out of range from BS
                for ns=1:length(Next_sink)
%                     if dts_tmp(j,ns) == min(dts_tmp(j,:))
                    if hop_tmp(j,ns) == min(hop_tmp(j,:))
                    % checks if CH is within range of an aggregator
                    % shortest distance possible
                        if CH(j).prev ==0
                        % CH hasn't received packets
                        % TRANSMIT ONLY
%                             ETx= Eelec*k + Eamp*k*dts_tmp(j,ns)^2;
                            ETx= Eelec*k + Eamp*k*(ceil(dts_tmp(j,ns)/range_C)*range_C)^2;
                            NET(CH(j).id).E=NET(CH(j).id).E-ETx;
                            CH(j).E = CH(j).E-ETx;

                            energy=energy+ETx;
                        else
                        % CH received packets
                        % TRANSMIT AND RECEIVE
                            %ERx=(EDA+Eelec)*k;
                            %ETx= Eelec*k + Eamp*k*CH(j).dts^2;
                            %Edis = (k*CH(j).prev*(Eelec + EDA) + k*(Eelec+Eamp*(CH(j).dts^2)));
%                             Edis = (k*(Eelec + EDA) + k*(Eelec+Eamp*(dts_tmp(j,ns)^2)));
                            Edis = (k*(Eelec + EDA) + k*(Eelec+Eamp*(ceil(dts_tmp(j,ns)/range_C)*range_C)^2));
                            NET(CH(j).id).E=NET(CH(j).id).E-Edis;
                            % line above didn't have a semicolon, could be
                            % intentional.
                            CH(j).E = CH(j).E-Edis;
                            energy=energy+Edis;
                            CH(j).prev =0;
                        end  
                        NET(Next_sink(ns).id).prev = 1;
                        break;
                    end
                    
                end
            end
            
            %Compute the reward
            Q_old = CH(j).Q;
            R= (p*(CH(j).E - min_E)/(max_E-min_E)+(q1/CH(j).hop));
                        
            %update Q_value
            CH(j).Q =Q_old + alpha*(R+ gamma * maxQ -Q_old) ;
            NET(CH(j).id).Q = CH(j).Q;
        elseif CH(j).E <= thres || thres<=0
        % recluster nodes    
            %------------------- BEGINNING OF RECLUSTERING --------------
            %CLUSTER HEAD ELECTION
            aln =0; %Alive nodes before reclustering
            % headcount of alive nodes
            for i=1:n
                NET(i).dest =0;
                NET(i).dts_ch =0;
                NET(i).hops_ch =0;
                NET(i).role=0;
                % clear node assignments
                if NET(i).E>0
                    NET(i).Eo = NET(i).E;
                    CM(i) = NET(i);
                    aln = aln+1; 
                else
                    NET(i).Eo = NET(i).E;
                    NET(i).cond = 0;
                    
                    
                end    
            end
%             CH_tot = ceil(aln/10)
            CH_tot = ceil(aln/10);
            % line above didn't have a semicolon, could be
            % intentional.
            %disp("NA ="+CH_tot+" ALN="+aln+" and N="+n)
            tot = 1;
            while(tot<=CH_tot)
                for i=1:n
                    %maxx= max([CM.Q]);
                    %disp(maxx);
                    if(CM(i).Q == max([CM.Q]) && CM(i).Q>=0)
%                         if tot == 1 && CM(i).dts>=range_C
                        if tot == 1 && CM(i).hop>=1 
                            NET(i).role=1;
                            CH(tot) = NET(i);
                            % plot(x,y,xm,ym,NET(i).x,NET(i).y,'Or');
                            CM(i).Q = 0;
                            tot =tot+1;                        
%                         elseif tot>1 &&  CM(i).dts>=range_C
                        elseif tot>1 &&  CM(i).hop>=1  
                            cl=0;
                            for t = 1:tot-1
                                dts = sqrt((CM(i).x-CH(t).x)^2 + (CM(i).y-CH(t).y)^2);
                                hop = ceil(dts/range_C);
                                if(hop == 1)
                                    cl= cl+1;
                                end
                            end
                            if cl==0
                                NET(i).role=1;
                                CH(tot) = NET(i);
                                % plot(x,y,xm,ym,NET(i).x,NET(i).y,'Or');

                                CM(i).Q = 0;
                                tot =tot+1;  
                            else
                                CM(i).Q = 0;
                            end
                        else
                            CM(i).Q = 0;
                        end

                    end
                       if tot>CH_tot
                           break;
                       end
                end
            end
            %END CLUSTER HEAD ELECTION

            %CLUSTER FORMATION
            for i=1:n
                for ch=1:CH_tot
                    dts_ch(i,ch) = sqrt((NET(i).x-CH(ch).x)^2 + (NET(i).y-CH(ch).y)^2);
                    hops_ch(i,ch) = ceil(dts_ch(i,ch)/range_C);
                    dts_ch(dts_ch==0)=NaN;
                    hops_ch(hops_ch==0)=NaN;
                end
                if NET(i).hop<=1
                % within range of BS
                    NET(i).dest = 0;
                    NET(i).dts_ch = 0;
                else
                    if NET(i).role==0
                        for ch = 1:CH_tot
                            dtsCh = sqrt((NET(i).x-CH(ch).x)^2 + (NET(i).y-CH(ch).y)^2);
                            hopCh = ceil(dtsCh/range_C);
%                             if NET(i).E>0 && dtsCh == min([dts_ch(i,:)])
                            if NET(i).E>0 && hopCh == min([hops_ch(i,:)]) 
                                NET(i).dest = CH(ch).id;
                                NET(i).hops_ch = min([hops_ch(i,:)]);
                                % figure(1);
                                % plot([NET(i).x CH(ch).x], [NET(i).y CH(ch).y])
                                % hold on;
                            end
                        end
                    end  
                end             
            end
            %END CLUSTER FORMATION
            for i=1:CH_tot
                ncm=1;
                for j=1:n
                    if NET(j).E>0
                        if(NET(j).dest == CH(i).id && NET(j).role==0)
                            %cluster(i,ncm)= [];
                            cluster(i,ncm)= NET(j);
                            ncm= ncm+1;
                        end
                    end
                    
                end
            end
            %------------------- END OF RECLUSTERING ---------------------

        end
        CH(j).prev=0;
    end
    %END INTERCLUSTER COMMUNICATION
    
    %Nodes around the sink node
    for l=1:n
        if NET(l).E>0
%             if NET(l).dts<=range_C && NET(l).role==0
            if NET(l).hop<=1 && NET(l).role==0
            % must not be a cluster head, and is within range to
            % the sink
                if NET(l).prev==0
                % no packets received
                % TRANSMIT ONLY
%                     ETx= Eelec*k + Eamp*k*NET(l).dts^2;
                    ETx= Eelec*k + Eamp*k*(NET(l).hop*range_C)^2;
                    NET(l).E=NET(l).E-ETx;
                    energy=energy+ETx;
                else
                % packets received
                % RECEIVE AND TRANSMIT
%                     Edis = (k*(Eelec + EDA) + k*(Eelec+Eamp*(NET(l).dts^2)));
                    Edis = (k*(Eelec + EDA) + k*(Eelec+Eamp*((NET(l).hop*range_C)^2)));
                    NET(l).E = NET(l).E-Edis;
                    energy=energy+Edis;
                    NET(l).prev =0;
                end
                
                %Compute the reward
                Q_old = NET(l).Q;
                R= (p*(NET(l).E - min_E)/(max_E-min_E)+(q1/NET(l).hop));

                %update Q_value
                NET(l).Q =Q_old + alpha*(R+ gamma * maxQ -Q_old) ;
                NET(l).Q = NET(l).Q;
            end
        end
        
        
    end
    
    %Compute round, Energy consumed per round and ...
    rnd = rnd+1;
    E_round(rnd) = energy;
    
    disp(rnd);
    dead=0;
    for i =1:n
        if NET(i).E<=0 || NET(i).cond==0
            dead = dead+1;
            NET(i).Q= -100;
            NET(i).cond = 0;
            op_nodes = n-dead;
            
        end
    end
    dead_rnd(rnd)=dead;
    op_nodes_rnd(rnd)=op_nodes;
    disp(op_nodes);
end
% END COMMUNICATION PHASE ------------------------------------------------
%%
% Plotting Simulation Results "Operating Nodes per Transmission" %
figure(2)
plot(1:rnd,op_nodes_rnd(1:rnd),'-','Linewidth',1);
%legend('RL-CEBRP');
title ({'Operating Nodes per Round';'' })
xlabel 'Rounds';
ylabel 'Operating Nodes';
hold on;

% Plotting Simulation Results "Energy consumed per Round" %
figure(3)
plot(1:rnd,E_round(1:rnd),'-','Linewidth',1);
%legend('RL-CEBRP')
title ({'Energy consumed per Round';'' })
xlabel 'Rounds';
ylabel 'Energy consumed in J';
hold on;

% % Plotting Simulation Results "Energy consumed per Round" %
figure(4)
plot(1:rnd,E_round(1:rnd),'-r','Linewidth',2);
%legend('RL-EBRP')
title ({'EER-RL'; 'Energy consumed per Round';})
xlabel 'Rounds';
ylabel 'Energy consumed in J';
hold on;
% 
% % Plotting Simulation Results "Cumulated dead nodes per Round" %
figure(5)
plot(1:rnd,dead_rnd(1:rnd),'-r','Linewidth',2);
%legend('RL-EBRP');
title ({'EER-RL'; 'Total dead nodes per Round';})
xlabel 'Rounds';
ylabel 'Dead Nodes';
hold on;
