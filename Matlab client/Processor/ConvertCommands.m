function motionConv = ConvertCommands(type, motions)
%CONVERTCOMMANDS Summary of this function goes here
%   Detailed explanation goes here
if (type~="ptpJp")
    motionConv=cell(1,size(motions,1));
    for i=1:size(motions,1)
        tempMot=motion(type, motions(i,1:3), motions(i,4:6));
        motionConv{i}=tempMot;
    end
else
    motionConv=cell(1,size(motions,1));
    for i=1:size(motions,1)
        tempMot=motion(type, motions(i,:));
        tempMot=tempMot.setCartVel(0.2);
        motionConv{i}=tempMot;
    end
end
end

