function Angles = GetInverseKinematicsLocalSolver(Target, Base, Shaft_Arm, Shaft_Needle, Shaft_Space, E1, Turn, PC)
% Обратная кинематика для iiwa. Округление до 5 знака
%
% Input 
% Target - целевая СК
% Base - База робота
% Shaft_Arm - Геометрическе параметры переходника + d
% Shaft_Needle - Длины спиц
% Shaft_Space - Расстояние по Z  между спицами. 1 - расстояние от штанги
% Е1 - избыточный угол А3, если Е1 = nan, то А3 любой
% Turn - положительный или отрицательный угол оси (0-255, иначе не используется)
% PС - предыдущая конфигурация (работает только, если есть 7 углов предыдущей конфигурацией, в иной случае не используется)
%
% Output
% Angles_1 - углы робота
% S - статус: 2-1 - количтесво решений, 0 - решения нет

% By Dmitry Kolpashikov, 2021

% Длины робота - полутано из importrobot('iiwa7.urdf');
% Они же начальные точки для FABRIK
iiwa_l = [0  0  150;  % 0-1 - 0 = Base
          0  0  190;  % 1-2 
          0  0  210;  % 2-3
          0  0  190;  % 3-4
          0  0  210;  % 4-5
          0  0  190;  % 5-6
          0  0  81;   % 6-7
          0  0  45+26]'; % 7-8 - 8 = End-Effector
iiwa_l = iiwa_l/1000;

Base = Base * makehgtform('translate', sum(iiwa_l(:,1:2),2));
Target = Base\Target; %Вектор хорды в СК Base
P = Target(1:3,4);
Z = Target(1:3,3);

a = sum(Shaft_Needle + Shaft_Space);
a = Shaft_Arm(1:3) + [0 0 a];
P = P - Target(1:3,1)*a(1) - Target(1:3,2)*a(2) - Target(1:3,3)*a(3); % Цель теперь фланец
P = P - Z*sum(iiwa_l(:,7:8),'all'); % Цель теперь шарнир 6
      
D = [sum(iiwa_l(3,3:4),2) sum(iiwa_l(3,5:6),2)]; % Начальные длины хорд

A4 = - 180 + acosd((D(1)^2+D(2)^2-norm(P)^2)/2/D(1)/D(2)); % 4й угол - обязан существовать

if isnan(E1) % Любой Е1
    A3 = 0;
else
    A3 = E1;
end
% Если 4й угол не существует или находится вне пределах допустимого
if sum(abs(imag(A4)))% || abs(A4) > rad2deg(2.094)
    Angles = [];
else
    Angles = zeros(8,7);
    Angles(:,4) = A4;
    Angles(:,3) = A3;

% Решение уравнения a*sin(x)+b*cos(x) = c;
% D2*(cos(A2)*cos(A4) + cos(A3)*sin(A2)*sin(A4)) + D1*cos(A2) = P(3);
% D(2)*cosd(A2)*cosd(A4) + D(2)*cosd(A3)*sind(A2)*sind(A4) + D(1)*cos(A2) = P(3)
% D(2)*cosd(A3)*sind(A4)*sind(A2) + (D(2)*cosd(A4) + D(1))*cos(A2) = P(3)
% https://ote4estvo.ru/matematika-v-tablicah/97814-reshenie-uravneniya-vida-a-sin-x-b-cos-x-c-metodom-vspomogatelnogo-argumenta.html
% https://studylib.ru/doc/3846999/uravnenie-a-sinx---b-cosx%3Dc-i-ego-primeneniya

    a = D(2) * cosd(A3) * sind(A4);
    b = D(2) * cosd(A4) + D(1);
    c = P(3);
    
    % a*sin(x)+b*cos(x) = c;
    
    if a && b % Если a*b =\= 0 Ищем вспомогательный угол (a = 0 и b = 0 невозможно)
        % Вспомогательный угол через синус
        ds(1) = asind(a/sqrt(a^2+b^2));
        ds(2) = sign(ds(1))*(180-abs(ds(1)));
        % Вспомогательный угол через косинус
        dc(1) = acosd(b/sqrt(a^2+b^2));
        dc(2) = -dc(1);
        % Вспомогательный угол через тангенс
        dt(1) = atand(a/b); 
        if dt(1) > 0
            dt(2) = dt(1) - 180;
        else
            dt(2) = dt(1) + 180;
        end
        
        % Итоговый вспомогательный угол должен присутствовать у всех
        d = []; k = 7;
        while size(d,1) ==0  || size(d,2)==0
            d = intersect(round(ds,k),round(dc,k));
            d = intersect(round(d,k),round(dt,k));
            k = k - 1;
        end
        
        Angles(1:4,2) = d + acosd(round(c/sqrt(a^2+b^2),5)); % 1й ответ
        Angles(5:8,2) = d - acosd(round(c/sqrt(a^2+b^2),5)); % 2й ответ
    elseif b % Если a = 0
        Angles(1:4,2) = acosd(round(c/b,5));
        Angles(5:8,2) = -Angles(1:4,2);
    else % Если b = 0
        Angles(1:4,2) = asind(round(c/a,5));
        Angles(5:8,2) = sign(Angles(1:4,2))*(180 - abs(Angles(1:4,2)));
    end
    
% D2*(sin(A4)*(sin(A1)*sin(A3) - cos(A1)*cos(A2)*cos(A3)) + cos(A1)*cos(A4)*sin(A2)) + D1*cos(A1)*sin(A2) = P(1)
% D(2)*sind(A4)*sind(A3)*sind(A1) - D(2)*sind(A4)*cosd(A2)*cosd(A3)*cos(A1) + D(2)*cos(A4)*sin(A2)*cos(A1) + D1*sin(A2)*cos(A1) = P(1)
% D(2)*sind(A4)*sind(A3)*sind(A1) + (-D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2) + D1*sind(A2))*cosd(A1)
% P(1)
    
    A2 = Angles(1,2);
    
    a = D(2)*sind(A4)*sind(A3);
    b = - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2) + D(1)*sind(A2);
    c = P(1);
    if abs(c) < 1e-5
        c = 0;
    end
        
    if a && b % Если a*b =\= 0 Ищем вспомогательный угол (a = 0 и b = 0 невозможно)
        % Вспомогательный угол через синус
        ds(1) = asind(a/sqrt(a^2+b^2));
        ds(2) = sign(ds(1))*(180-abs(ds(1)));
        % Вспомогательный угол через косинус
        dc(1) = acosd(b/sqrt(a^2+b^2));
        dc(2) = -dc(1);
        % Вспомогательный угол через тангенс
        dt(1) = atand(a/b); 
        if dt(1) > 0
            dt(2) = dt(1) - 180;
        else
            dt(2) = dt(1) + 180;
        end
        
        % Итоговый вспомогательный угол должен присутствовать у всех
        d = []; k = 7;
        while size(d,1) == 0 || size(d,2) == 0
            d = intersect(round(ds,k),round(dc,k));
            d = intersect(round(d,k),round(dt,k));
            k = k - 1;
        end
        
        Angles(1,1) = d + acosd(round(c/sqrt(a^2+b^2),5)); % 1й ответ
        Angles(2,1) = d - acosd(round(c/sqrt(a^2+b^2),5)); % 2й ответ
    elseif b % Если a = 0
        Angles(1,1) = acosd(c/b);
        Angles(2,1) = -Angles(1,1);
    else % Если b = 0
        Angles(1,1) = asind(c/a);
        Angles(2,1) = sign(Angles(1,1))*(180 - abs(Angles(1,1)));
    end
    
    %
    A2 = Angles(5,2);
    
    a = D(2)*sind(A4)*sind(A3);
    b = - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2) + D(1)*sind(A2);
    c = P(1);
    if abs(c) < 1e-5
        c = 0;
    end
    
    if a && b % Если a*b =\= 0 Ищем вспомогательный угол (a = 0 и b = 0 невозможно)
        % Вспомогательный угол через синус
        ds(1) = asind(a/sqrt(a^2+b^2));
        ds(2) = sign(ds(1))*(180-abs(ds(1)));
        % Вспомогательный угол через косинус
        dc(1) = acosd(b/sqrt(a^2+b^2));
        dc(2) = -dc(1);
        % Вспомогательный угол через тангенс
        dt(1) = atand(a/b); 
        if dt(1) > 0
            dt(2) = dt(1) - 180;
        else
            dt(2) = dt(1) + 180;
        end
        
        % Итоговый вспомогательный угол должен присутствовать у всех
        d = []; k = 7;
        while size(d,1) == 0  || size(d,2)== 0
            d = intersect(round(ds,k),round(dc,k));
            d = intersect(round(d,k),round(dt,k));
            k = k - 1;
        end
        
        Angles(5,1) = d + acosd(round(c/sqrt(a^2+b^2),5)); % 1й ответ
        Angles(6,1) = d - acosd(round(c/sqrt(a^2+b^2),5)); % 2й ответ
    elseif b % Если a = 0
        Angles(5,1) = acosd(c/b);
        Angles(6,1) = -Angles(5,1);
    else % Если b = 0
        Angles(5,1) = asind(c/a);
        Angles(6,1) = sign(Angles(5,1))*(180 - abs(Angles(5,1)));
    end
    
% D1*sin(A1)*sin(A2) - D2*(sin(A4)*(cos(A1)*sin(A3) + cos(A2)*cos(A3)*sin(A1)) - cos(A4)*sin(A1)*sin(A2)) = P(2)   
% D(1)*sind(A2)*sind(A1) - D(2)*sind(A4)*sind(A3)*cosd(A1) - D(2)*sind(A4)*cosd(A2)*cosd(A3)*sind(A1) + D(2)*cosd(A4)*sind(A2)*sind(A1) = P(2)
% (D(1)*sind(A2) - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2))*sind(A1) - D(2)*sind(A4)*sind(A3)*cosd(A1) = P(2)
% P(2)

    A2 = Angles(1,2);
    
    a = D(1)*sind(A2) - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2);
    b = - D(2)*sind(A4)*sind(A3);
    c = P(2);
    if abs(c) < 1e-5
        c = 0;
    end
    
    if a && b % Если a*b =\= 0 Ищем вспомогательный угол (a = 0 и b = 0 невозможно)
        % Вспомогательный угол через синус
        ds(1) = asind(a/sqrt(a^2+b^2));
        ds(2) = sign(ds(1))*(180-abs(ds(1)));
        % Вспомогательный угол через косинус
        dc(1) = acosd(b/sqrt(a^2+b^2));
        dc(2) = -dc(1);
        % Вспомогательный угол через тангенс
        dt(1) = atand(a/b); 
        if dt(1) > 0
            dt(2) = dt(1) - 180;
        else
            dt(2) = dt(1) + 180;
        end
        
        % Итоговый вспомогательный угол должен присутствовать у всех
        d = []; k = 7;
        while size(d,1) ==0  || size(d,2)==0
            d = intersect(round(ds,k),round(dc,k));
            d = intersect(round(d,k),round(dt,k));
            k = k - 1;
        end
        
        Angles(3,1) = d + acosd(round(c/sqrt(a^2+b^2),5)); % 1й ответ
        Angles(4,1) = d - acosd(round(c/sqrt(a^2+b^2),5)); % 2й ответ
    elseif b % Если a = 0
        Angles(3,1) = acosd(c/b);
        Angles(4,1) = -Angles(3,1);
    else % Если b = 0
        Angles(3,1) = asind(c/a);
        Angles(4,1) = sign(Angles(3,1))*(180 - abs(Angles(3,1)));
    end
    
    %
    A2 = Angles(5,2);
    
    a = D(1)*sind(A2) - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2);
    b = - D(2)*sind(A4)*sind(A3);
    c = P(2);
    if abs(c) < 1e-5
        c = 0;
    end
    
    if a && b % Если a*b =\= 0 Ищем вспомогательный угол (a = 0 и b = 0 невозможно)
        % Вспомогательный угол через синус
        ds(1) = asind(a/sqrt(a^2+b^2));
        ds(2) = sign(ds(1))*(180-abs(ds(1)));
        % Вспомогательный угол через косинус
        dc(1) = acosd(b/sqrt(a^2+b^2));
        dc(2) = -dc(1);
        % Вспомогательный угол через тангенс
        dt(1) = atand(a/b); 
        if dt(1) > 0
            dt(2) = dt(1) - 180;
        else
            dt(2) = dt(1) + 180;
        end
        
        % Итоговый вспомогательный угол должен присутствовать у всех
        d = []; k = 7;
        while size(d,1) ==0  || size(d,2)==0
            d = intersect(round(ds,k),round(dc,k));
            d = intersect(round(d,k),round(dt,k));
            k = k - 1;
        end
        
        Angles(7,1) = d + acosd(round(c/sqrt(a^2+b^2),5)); % 1й ответ
        Angles(8,1) = d - acosd(round(c/sqrt(a^2+b^2),5)); % 2й ответ
    elseif b % Если a = 0
        Angles(7,1) = acosd(c/b);
        Angles(8,1) = -Angles(7,1);
    else % Если b = 0
        Angles(7,1) = asind(c/a);
        Angles(8,1) = sign(Angles(7,1))*(180 - abs(Angles(7,1)));
    end
    
    Angles = real(Angles); % На случай если a/a > 1
    
    Angles(any(isnan(Angles), 2), :) = []; % Убираем строки с НаН
        
    for i = size(Angles,1):-1:1 % Проверяем чтобы все углы соответствовали целевой точке
        A1 = Angles(i,1); A2 = Angles(i,2);
        x = D(2)*sind(A4)*sind(A3)*sind(A1) + (-D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2) + D(1)*sind(A2))*cosd(A1);
        y = (D(1)*sind(A2) - D(2)*sind(A4)*cosd(A2)*cosd(A3) + D(2)*cosd(A4)*sind(A2))*sind(A1) - D(2)*sind(A4)*sind(A3)*cosd(A1);
        if abs(x - P(1)) > 1e-5 || abs(y - P(2)) > 1e-5 % Если угол не подходит
            Angles(i,:) = []; % Удаляем
        end
    end
                
    for i = 1:size(Angles,1) % Докидываем 5-6-7 углы
        T0 = makehgtform('zrotate',deg2rad(Angles(i,1)));
        T0 = T0 * makehgtform('yrotate',deg2rad(Angles(i,2)));
        T0 = T0 * makehgtform('zrotate',deg2rad(180));
        T0 = T0 * makehgtform('zrotate',deg2rad(Angles(i,3)));
        T0 = T0 * makehgtform('yrotate',deg2rad(Angles(i,4)));
        T0 = T0 * makehgtform('zrotate',deg2rad(180));
        
        b = T0(1:3,1:3)\Z;
        Angles(i,5) = atan2d(b(2),b(1));
        Angles(i,6) = acosd([0 0 1]*b/norm(b));
        
        T0 = T0 * makehgtform('zrotate',deg2rad(Angles(i,5)));
        T0 = T0 * makehgtform('yrotate',deg2rad(Angles(i,6)));
        
        b = T0(1:3,1:3)\Target(1:3,1);        
        Angles(i,7) = atan2d(b(2),b(1));
    end
    
    b = []; % Заготовка под список наборов углов-повторов
    for i = 1:size(Angles,1)-1
        for j = i+1:size(Angles,1)
            a = Angles(i,:)-Angles(j,:); % Разница между 2 наборами углов
            if sum(abs(a)) < 1e-2 % Если абсолютная разница между наборами меньше 1e-3 (взято с потолка)
                Angles(i,:) = (Angles(i,:)+Angles(j,:))/2; % 1у набору присваиваем среднее между этими наборами
                b = [b j];
            end
        end
    end % Фильтр повторов, более жесткий чем в WB
    Angles(b,:) = []; % Удаляем все углы из списка
     
    a = size(Angles,1);
    for i = 0:a-1
        %100 - 1
        Angles(a+7*i+1,:) = Angles(i+1,:);
        Angles(a+7*i+1,1) = Angles(i+1,1)+180;
        Angles(a+7*i+1,2) = -Angles(i+1,2);  
        Angles(a+7*i+1,3) = Angles(i+1,3)+180;
        if Angles(a+7*i+1,1) > 180
            Angles(a+7*i+1,1) = Angles(a+7*i+1,1) - 360;
        end
        if Angles(a+7*i+1,3) > 180
            Angles(a+7*i+1,3) = Angles(a+7*i+1,3) - 360;
        end

        %010 - 2
        Angles(a+7*i+2,:) = Angles(i+1,:);
        Angles(a+7*i+2,3) = Angles(i+1,3)+180;
        Angles(a+7*i+2,4) = -Angles(i+1,4);  
        Angles(a+7*i+2,5) = Angles(i+1,5)+180;
        if Angles(a+7*i+2,3) > 180
            Angles(a+7*i+2,3) = Angles(a+7*i+2,3) - 360;
        end
        if Angles(a+7*i+2,5) > 180
            Angles(a+7*i+2,5) = Angles(a+7*i+2,5) - 360;
        end

        %001 - 3
        Angles(a+7*i+3,:) = Angles(i+1,:);
        Angles(a+7*i+3,5) = Angles(i+1,5)+180;
        Angles(a+7*i+3,6) = -Angles(i+1,6);  
        Angles(a+7*i+3,7) = Angles(i+1,7)+180;
        if Angles(a+7*i+3,5) > 180
            Angles(a+7*i+3,5) = Angles(a+7*i+3,5) - 360;
        end
        if Angles(a+7*i+3,7) > 180
            Angles(a+7*i+3,7) = Angles(a+7*i+3,7) - 360;
        end

        %011 - 4
        Angles(a+7*i+4,:) = Angles(i+1,:);
        Angles(a+7*i+4,3) = Angles(i+1,3)+180;
        Angles(a+7*i+4,4) = -Angles(i+1,4);  
        Angles(a+7*i+4,6) = -Angles(i+1,6);  
        Angles(a+7*i+4,7) = Angles(i+1,7)+180;
        if Angles(a+7*i+4,3) > 180
            Angles(a+7*i+4,3) = Angles(a+7*i+4,3) - 360;
        end
        if Angles(a+7*i+4,7) > 180
            Angles(a+7*i+4,7) = Angles(a+7*i+4,7) - 360;
        end

        %110 - 5
        Angles(a+7*i+5,:) = Angles(i+1,:);
        Angles(a+7*i+5,1) = Angles(i+1,1)+180;
        Angles(a+7*i+5,2) = -Angles(i+1,2);  
        Angles(a+7*i+5,4) = -Angles(i+1,4);  
        Angles(a+7*i+5,5) = Angles(i+1,5)+180;
        if Angles(a+7*i+5,1) > 180
            Angles(a+7*i+5,1) = Angles(a+7*i+5,1) - 360;
        end
        if Angles(a+7*i+5,5) > 180
            Angles(a+7*i+5,5) = Angles(a+7*i+5,5) - 360;
        end

        %101 - 6
        Angles(a+7*i+6,:) = Angles(i+1,:);
        Angles(a+7*i+6,1) = Angles(i+1,1)+180;
        Angles(a+7*i+6,2) = -Angles(i+1,2);  
        Angles(a+7*i+6,3) = Angles(i+1,3)+180;
        Angles(a+7*i+6,5) = Angles(i+1,5)+180;
        Angles(a+7*i+6,6) = -Angles(i+1,6);  
        Angles(a+7*i+6,7) = Angles(i+1,7)+180;
        if Angles(a+7*i+6,1) > 180
            Angles(a+7*i+6,1) = Angles(a+7*i+6,1) - 360;
        end
        if Angles(a+7*i+6,3) > 180
            Angles(a+7*i+6,3) = Angles(a+7*i+6,3) - 360;
        end
        if Angles(a+7*i+6,5) > 180
            Angles(a+7*i+6,5) = Angles(a+7*i+6,5) - 360;
        end
        if Angles(a+7*i+6,7) > 180
            Angles(a+7*i+6,7) = Angles(a+7*i+6,7) - 360;
        end

        %111 - 7
        Angles(a+7*i+7,:) = Angles(i+1,:);
        Angles(a+7*i+7,1) = Angles(i+1,1)+180;
        Angles(a+7*i+7,2) = -Angles(i+1,2);  
        Angles(a+7*i+7,4) = -Angles(i+1,4);  
        Angles(a+7*i+7,6) = -Angles(i+1,6);  
        Angles(a+7*i+7,7) = Angles(i+1,7)+180;
        if Angles(a+7*i+7,1) > 180
            Angles(a+7*i+7,1) = Angles(a+7*i+7,1) - 360;
        end
        if Angles(a+7*i+7,7) > 180
            Angles(a+7*i+7,7) = Angles(a+7*i+7,7) - 360;
        end
    end % Дополнительные углы
        
    b = []; % Заготовка под список наборов углов вне предела
    for i = 1:size(Angles,1) % Фильтр предельных значений
        a = abs(Angles(i,1)) < 165 && abs(Angles(i,2)) < 115 &&...       
        abs(Angles(i,3)) < 165 && abs(Angles(i,4)) < 115 &&...         
        abs(Angles(i,5)) < 165 && abs(Angles(i,6)) < 115 &&...      
        abs(Angles(i,7)) < 170;                                       
        if ~a % Если набор не соответствует требованиям
            b = [b i]; % Докибываем его в список
        end
    end
    Angles(b,:) = []; % Удаляем все углы из списка
    
    if ~isnan(E1)
        a = Angles(:,3) == E1;
        Angles = Angles(a,:);
    end
    
    % Turn
    if Turn >= 0 && Turn <= 255
        Turn = dec2bin(Turn,7);
        for i = 0:6
            a = Angles(:,i+1) < 0;
            a = a == str2num(Turn(7-i));
            Angles = Angles(a,:);
        end
    end
    
    % PC
    if length(PC) == 7
        a = PC - Angles;
        a = sum(abs(a),2);
        [~,a] = min(a);
        Angles = Angles(a,:);
    else
        [~,pt] = sort(sum(abs(Angles),2));
        Angles = Angles(pt,:);
    end
    Angles = unique(round(Angles,5),'row'); % Убираем повторы
end 
end