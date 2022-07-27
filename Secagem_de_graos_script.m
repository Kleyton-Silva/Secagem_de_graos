%% Caso de Estudo - Secagem de Grãos

% Definido s como transformada de laplace:
clear; % Limpa workspace
close all; %Fechar todas janelas de figuras abertas
clc; % Limpar Command Window

s = tf('s'); % Define s cmo a transformada de laplace

%% Dados e Modelos:

G1 = 1/(1.6*s + 1);
G2 = 1/(40*s + 1);
G3 = 0.8/(50*s + 1);

G4 = 7/(0.7*s + 1);
G5 = 0.5/(0.5*s + 1);
G6 = 3/(0.5*s + 1);
G7 = 5/(3*s + 1);


%% Dados e Modelos manipulado:

% Abertura da válvula de vapor para emperatura do ar quente na entrada do
% secador
GaT = 5/(1.6*s + 1);

% Temperatura do ar quente na entrada do secador para umidade do grão na
% saída do secador
GTH = 5/(40*s + 1);

% Acionamento do motor elétrico da esteira para velocidade da esteira
GMVe = 3/(0.5*s + 1);

% Velocidade da esteira para camada de grãos na esteira
GVeL = 5/(3*s + 1);

% Pertubação - Pressão na linha de vapor para Temperatura do ar quente na
% entrada do secador
GpT = 2/(1.6*s + 1);

% Perturbação - Temperatura do ar na entrada do aquecedor para Temperatura
% do ar quente na entrada do secador
GTaT = 1/(1.6*s + 1);

% Perturbação - Umidade do grão no slio para umidade do grão na saída do
% secador
GHeH = 1/(40*s + 1);

% Perturbação - Velocidade da esteira para umidade do grão na saída do
% secador
GVeH = 0.8/(50*s + 1);

% Perturbação - Vazão de grão do silo na esteira para camada de grãos na
% esteira
GFL = 35/((3*s + 1)*(0.7*s + 1));

% Perturbação - Umidade de grão no silo para camada de grãos na esteira
GHeVe = 0.5/(0.5*s + 1);


%% Requisitor para controle da umidade H(s):

% Erro nulo para mudanças de referência do tipo degrau
% Erro nulo para perturbações do tipo degrau
% t5% de malha fechada duas vezes mais rápida que malha aberta para 
% Respostas de seguimento e rejeição de perturbação. Fazendo essa conta
% t5% <= 60seg
% MP = 5%


%% Objetivo da Etrutura de Controle de H(s):

% Foi utilizado uma estrutura de controle em cascata para o sistema, pois o
% processo possui um medidor para a Temperatura do ar quente na entrada do
% secador (T) disponível, e as perturbações, temperatura do ar na entrada do
% aquecedor (Ta) e pressão na linha de vapor (p), influênciam diretamente
% na temperatura do ar quente na entrada do secador. Desta forma a
% estrutura de controle em cascata é uma alternativa viavél e indicada para
% melhorar a rejeição das perturbações, além de facilitar o projeto dos
% controladores da estrutura.

% Objetivo de cada controlador:

% CT: Seguir as referências dadas pelo controlador CH, com erro nulo em 
% regime permanete com tempo de acomodação para rejeição e perturbação pelo 
% menos 10x mais rápida que a malha de controle CH. Para auxiliar CT foi 
% adicionado um CFF na perturbação (p), pois esta perturbação é mensurável.

%Requsitos para CT:
% Sobressinal 5%
% t5% = 6 seg para referência e perturbação
% rejeitar perturbação

% CH: Seguir as referências de H com erro nulo em regime permanete com
% tempo de acomodação inferior a 60seg, rejeitar as perturbações com erro
% nulo em regime permanente com tempo de acomodação inferior a 60 seg. Para
% auxiliar CH foi adicionado um CFF na perturbação (Ve), pois esta 
% perturbação é mensurável.

%Requsitos para CH:
% Sobressinal 5%
% t5% = 60 seg para referência e perturbação
% rejeitar perturbação


%% Projeto de CT:

%MP = 0, t5 = 6
Kc = 0.8;
Ti = 1.6;

%Controlador:
CT = (Kc*(Ti*s+1))/(Ti*s);
Tr = (CT*GaT)/(1+CT*GaT);
Tr = (minreal(Tr,0.0001));


%% Análise do Controlador CT

figure;
step(Tr) % Resposta ao degrau de Tr
grid on

figure;
pzmap(Tr) % Diagrama Polo e Zero - DPZ
grid on

% Como podemos observar aparece um zero indesejado, projetamos um filtro
% para retirar esse zero:
FCT = 1/(Ti*s+1);
TrfT = FCT*Tr;
TrfT = minreal(TrfT,0.00001);

figure;
step(TrfT) % Resposta ao degrau de Trf
grid on

figure;
pzmap(TrfT) % Diagrama Polo e Zero - DPZ
grid on

% Tempo de 5% para Referência:
info = stepinfo(TrfT,'SettlingTimeThreshold',0.05);
T5MF = info.SettlingTime;

% Sobressinal da referência:
MP = info.Overshoot;

% Ganho DC = 1:
GDC = dcgain(Tr);


% Verificando agora para Perturbarção, Calculando Tp(s):
Tp = GTaT/(1+CT*GaT);
Tp = zpk(minreal(Tp,0.0001))


% A resposta a entrada ao degrau em Ta, apresenta a rejeição conforme
% esperado.

figure; 
step(Tp) % Resposta ao degrau de Tp
grid on

figure;
pzmap(Tp) % Diagrama polo zero DPZ
grid on

% Como esperado o Ganho DC é igual a zero logo atende as especificações
% desejadas.
GDC = dcgain(Tp);


% Controlador FF para a perturbação p(s):

Cffp = -2/5;


%% Projeto de CH:

%MP = 0.05, t5 = 60
Kc = 0.6;
Ti = (0.6)/(8*(0.072^(2)));

%Controlador:
CH = (Kc*(Ti*s+1))/(Ti*s);
Tr = (CH*GTH)/(1+CH*GTH);
Tr = (minreal(Tr,0.0001));


%% Análise do Controlador CH

figure;
step(Tr) % Resposta ao degrau de Tr
grid on

figure;
pzmap(Tr) % Diagrama Polo e Zero - DPZ
grid on

% Como podemos observar aparece um zero indesejado, projetamos um filtro
% para retirar esse zero:
FCH = 1/(Ti*s+1);
TrfH = FCH*Tr;
TrfH = minreal(TrfH,0.00001);

figure;
step(TrfH) % Resposta ao degrau de Trf
grid on

figure;
pzmap(TrfH) % Diagrama Polo e Zero - DPZ
grid on

% Tempo de 5% para Referência:
info = stepinfo(TrfH,'SettlingTimeThreshold',0.05);
T5MF = info.SettlingTime;

% Sobressinal da referência:
MP = info.Overshoot;

% Ganho DC = 1:
GDC = dcgain(Tr);


% Verificando agora para Perturbarção, Calculando He(s):
Tp = GHeH/(1+CH*GTH);
Tp = zpk(minreal(Tp,0.0001));


% A resposta a entrada ao degrau em He, apresenta a rejeição conforme
% esperado.

figure; 
step(Tp) % Resposta ao degrau de Tp
grid on

figure;
pzmap(Tp) % Diagrama polo zero DPZ
grid on

% Como esperado o Ganho DC é igual a zero logo atende as especificações
% desejadas.
GDC = dcgain(Tp);


% Controlador FF para a perturbação Ve(s):

CffVe = (-32*s - 0.8)/(250*s + 5);


%% Requisitor para controle da camada de grãos L(s):

% Erro nulo para mudanças de referência do tipo degrau
% Erro nulo para perturbações do tipo degrau
% t5% <= 5 para tespostas de seguimento e rejeição de perturbação.
% MP = 0


%% Objetivo da Etrutura de Controle de L(s):

% Foi utilizado uma estrutura de controle em cascata para o sistema, pois o
% processo possui um medidor para a velocidade da esteira (Ve), e a 
% perturbação, umidade do grão no silo (He),influência diretamente
% na velocidade da esteira. Desta forma a estrutura de controle em cascata 
%é uma alternativa viavél e indicada para melhorar a rejeição das 
%perturbações, além de facilitar o projeto dos controladores da estrutura.

% Objetivo de cada controlador:

% CVe: Seguir as referências dadas pelo controlador CL, com erro nulo em 
% regime permanete com tempo de acomodação para rejeição e perturbação pelo 
% menos 10x mais rápida que a malha de controle CL.

%Requsitos para CVe:
% Sobressinal = 0
% t5% <= 0,5 seg para referência e perturbação
% rejeitar perturbação

% CL: Seguir as referências de L com erro nulo em regime permanete com
% tempo de acomodação inferior a 5 seg, rejeitar as perturbações com erro
% nulo em regime permanente com tempo de acomodação inferior a 5 seg.

%Requsitos para CL:
% Sobressinal = 0
% t5% <= 5 seg para referência e perturbação
% rejeitar perturbação


%% Projeto de CVe:

%MP = 0, t5 = 0,5
Kc = 8.6/3;
Ti = 8.6/46.08;

%Controlador:
CVe = (Kc*(Ti*s+1))/(Ti*s);
Tr = (CVe*GMVe)/(1+CVe*GMVe);
Tr = (minreal(Tr,0.0001));


%% Análise do Controlador CVe

figure;
step(Tr) % Resposta ao degrau de Tr
grid on

figure;
pzmap(Tr) % Diagrama Polo e Zero - DPZ
grid on

% Como podemos observar aparece um zero indesejado, projetamos um filtro
% para retirar esse zero:
FCVe = 1/(Ti*s+1);
TrfVe = FCVe*Tr;
TrfVe = minreal(TrfVe,0.00001);

figure;
step(TrfVe) % Resposta ao degrau de Trf
grid on

figure;
pzmap(TrfVe) % Diagrama Polo e Zero - DPZ
grid on

% Tempo de 5% para Referência:
info = stepinfo(TrfVe,'SettlingTimeThreshold',0.05);
T5MF = info.SettlingTime;

% Sobressinal da referência:
MP = info.Overshoot;

% Ganho DC = 1:
GDC = dcgain(Tr);

% Verificando agora para Perturbarção, Calculando Tp(s):
Tp = GHeVe/(1+CVe*GMVe);
Tp = zpk(minreal(Tp,0.0001))


% A resposta a entrada ao degrau em Ta, apresenta a rejeição conforme
% esperado.

figure; 
step(Tp) % Resposta ao degrau de Tp
grid on

figure;
pzmap(Tp) % Diagrama polo zero DPZ
grid on

% Como esperado o Ganho DC é igual a zero logo atende as especificações
% desejadas.
GDC = dcgain(Tp);


%% Projeto de CL:

%MP = 0, t5 = 5
Kc = 0.952;
Ti = (5*0.952)/(3*0.9216);

%Controlador:
CL = (Kc*(Ti*s+1))/(Ti*s);
Tr = (CL*GVeL)/(1+CL*GVeL);
Tr = (minreal(Tr,0.0001))


%% Análise do Controlador CL

figure;
step(Tr) % Resposta ao degrau de Tr
grid on

figure;
pzmap(Tr) % Diagrama Polo e Zero - DPZ
grid on

% Como podemos observar aparece um zero indesejado, projetamos um filtro
% para retirar esse zero:
FCL = 1/(Ti*s+1);
TrfL = FCL*Tr;
TrfL = minreal(TrfL,0.00001);

figure;
step(TrfL) % Resposta ao degrau de Trf
grid on

figure;
pzmap(TrfL) % Diagrama Polo e Zero - DPZ
grid on

% Tempo de 5% para Referência:
info = stepinfo(TrfL,'SettlingTimeThreshold',0.05);
T5MF = info.SettlingTime;

% Sobressinal da referência:
MP = info.Overshoot;

% Ganho DC = 1:
GDC = dcgain(Tr);

%%
% Verificando agora para Perturbarção, Calculando Tp(s):
Tp = GFL/(1+CL*GVeL)
Tp = zpk(minreal(Tp,0.0001))


% A resposta a entrada ao degrau em Ta, apresenta a rejeição conforme
% esperado.

figure; 
step(Tp) % Resposta ao degrau de Tp
grid on

figure;
pzmap(Tp) % Diagrama polo zero DPZ
grid on

% Tempo de 5% para Referência:
info = stepinfo(Tp,'SettlingTimeThreshold',0.05)
T5MF = info.SettlingTime

% Sobressinal da referência:
MP = info.Overshoot


% Como esperado o Ganho DC é igual a zero logo atende as especificações
% desejadas.
GDC = dcgain(Tp)


%% Simulação do Sitemas Completo:
out = sim('secagem_de_graos_simulink.slx'); % Executa o arquivo do simulink

% Cenário simulado:
% Mudança de reférência do tipo degrau em 50seg para H(s)
% Mudança de reférência do tipo degrau em 10seg para L(s)
% 10seg Perturbação em p com amplitude 1
% 7seg Perturbação em Ta com amplitude 1
% 20seg Perturbação em He com amplitude 1
% 20seg Perturbação em F com amplitude 1

% Erros dos controladores CH e CT
figure;
subplot(2,1,1)
plot(out.erro1.signals.values(:,1), 'LineWidth', 2)
xlabel("Time(s)")
ylabel("Erro de CH(s)")
grid on
xlim([0 60])
ylim([-10 10])
yticks([-10:4:60])

subplot(2,1,2)
plot(out.erro1.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Erro de CT(s)")
grid on
xlim([0 60])
ylim([-10 10])
yticks([-10:4:60])

% Sinal do erro dos controladores CH(s), e CT(s), observa-se que os dois
% controladores conseguem sempre levar o erro para zero após cada
% perturbação ou mudanção de referência garantindo assim o erro nulo em
% regime permanente

% Erros dos controladores CL e CVe
figure;
subplot(2,1,1)
plot(out.erro2.signals.values(:,1), 'LineWidth', 2)
xlabel("Time(s)")
ylabel("Erro de CL(s)")
grid on
xlim([0 60])
ylim([-10 10])
yticks([-10:4:60])

subplot(2,1,2)
plot(out.erro2.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Erro de CVe(s)")
grid on
xlim([0 60])
ylim([-10 10])
yticks([-10:4:60])

% Sinal do erro do controlador CL(s),  observa-se que ele conseguem 
% sempre levar o erro para zero após cada perturbação ou mudanção de 
% referência mas o controlador Cve(s)leva o erro para proximo de -7, após
% a perturbação F(s) atuar


% Controle de H(s):
figure;
plot(out.Hs.signals.values(:,1),'LineWidth',2)
hold on
plot(out.Hs.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Hs")
legend('Ref','Hs')
grid on

% Observa-se que o controlador CH consegue seguir as referências dadas
% com o sobressinal dentro do requisito, no instante 10 quando a
% perturbação p atua no sistema observa-se que a diversas ociçaões. E que
% também o cff ajuda a ignorar a perturbação de Ve;

% Controle de T(s):
figure;
plot(out.Ts.signals.values(:,1),'LineWidth',2)
hold on
plot(out.Ts.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Ts")
legend('Ref','Ts')
grid on

% Observa-se que o controlador CT se mantem bem acima da referência;

% Controle de L(s):
figure;
plot(out.Ls.signals.values(:,1),'LineWidth',2)
hold on
plot(out.Ls.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Ls")
legend('Ref','Ls')
grid on

% Observa-se que o controlador CL consegue seguir as referências dadas
% sem sobressinal, e quando a perturbação F(s) atua ocorre um grande
% sobressinal de 400% fora dos requisitos

% Controle de Ve(s):
figure;
plot(out.Ves.signals.values(:,1),'LineWidth',2)
hold on
plot(out.Ves.signals.values(:,2),'LineWidth',2)
xlabel("Time(s)")
ylabel("Ves")
legend('Ref','Ves')
grid on

% Observa-se que o controlador CVe consegue seguir quase que perfeitamente
% a referência, que é sempre negativa;
