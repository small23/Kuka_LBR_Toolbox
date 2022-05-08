function [time , status, msg]= PingConn(obj)
%PINGCONN Summary of this function goes here
%   Detailed explanation goes here
time=zeros(1,10000);
clk=tic();
cnt=0;
flagErr=0;
while toc(clk)<5
    [~, status, msg] = ReceiveResponse(obj, "<CCC");
    if (status~=0)
        flagErr=1;
        break;
    end
    time(cnt+1)=tic();
    cnt=cnt+1;
end
time=time(1:cnt);
if (time>0)
    for i=size(time,2):-1:2
        time(i)=(time(i)-time(i-1))/1e4;
    end
    time(1)=(time(1)-clk)/1e4;
end
if (flagErr==0)
    msg = ['Mean time: ',num2str(mean(time)), 'ms, total packages: ',num2str(size(time,2))];
    status = 1;
    disp(['Mean time: ',num2str(mean(time)), 'ms']);
    disp(['Total packages: ',num2str(size(time,2))]);
end
end

