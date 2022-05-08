function res = GetForwardKinematicsLocalSolver(angles)
%GETFORWARDKINEMATICSLOCALSOLVER Summary of this function goes here
%   Detailed explanation goes here
iiwaAng=[0,-angles];
currentCoord=zeros(9,3);

iiwaLn=[156,184,184,216,184,216,126,26]; % Длины
baseOut = eye(4);
base=[1,0,0;0,1,0;0,0,1];
for i=1:8
    if i==5
        iiwaAng(5)=-iiwaAng(5);
    end
    if (mod(i,2))
        base=rotMatY(iiwaAng(i))*base;
    else
        base=rotMatZ(iiwaAng(i))*base;
    end
    currentCoord(i+1,:)=currentCoord(i,:)+[0,0,iiwaLn(i)]* base;
    baseOut(i*4+1:i*4+1+3, 1:4) = [base currentCoord(i+1,:)'; [0 0 0 1]];
    
end
res.JBase=baseOut(1:4,:);
res.J1=baseOut(5:8,:);
res.J2=baseOut(9:12,:);
res.J3=baseOut(13:16,:);
res.J4=baseOut(17:20,:);
res.J5=baseOut(21:24,:);
res.J6=baseOut(25:28,:);
res.J7=baseOut(29:32,:);
res.Flange=baseOut(33:36,:);
end

function matr=rotMatY(angle)
matr=[cos(angle), 0, sin(angle);0 1 0; -sin(angle), 0, cos(angle)];
end

function matr=rotMatZ(angle)
matr=[cos(angle), -sin(angle),0;sin(angle), cos(angle), 0; 0 0 1];
end

