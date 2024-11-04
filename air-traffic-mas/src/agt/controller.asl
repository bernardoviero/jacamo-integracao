include('std_agents').
include('stdlib').
include('string').

!start.

tempo_atual(1). 
pousos_restantes(6).
avioes_pousados([]). 
propostas_processadas([]). 
contador_pousos(0). 
avioes_para_decolar([]). 

+!start <-
    joinWorkspace(w);
    lookupArtifact(simulationInterface, SimID);
    focus(SimID);
    .broadcast(tell, tempo_atual(1));
    !iniciar_pouso.

+!iniciar_pouso : tempo_atual(T) & pousos_restantes(N) <- 
    if (N > 0) {
        .println("Iniciando negociacoes no tempo ", T);
        !notificar_avioes(T);
        .wait(4000);
        !aguardar_todas_propostas(T);
        !encontrar_melhor_aviao(T);
        ?melhor_aviao(Aviao);
        .send(Aviao, tell, pouso_aprovado);
        .println(Aviao, " recebeu autorizacao para pousar no tempo ", T);
        !atualizar_pousos_restantes(Aviao);
        .wait(3000);
        !verificar_decolagem;
    } else {
        .println("Todos os pousos foram realizados.");
        !verificar_decolagem;
    }.

+!kqml_received(Aviao, tell, decolagem_solicitada, _) <- 
    ?avioes_para_decolar(ListaDecolagem);
    ListaNova = [Aviao | ListaDecolagem];
    -avioes_para_decolar(ListaDecolagem);
    +avioes_para_decolar(ListaNova);
    .println(Aviao, " esta aguardando autorizacao para decolar.").

+!verificar_decolagem : contador_pousos(CP) & avioes_para_decolar(AvioesDecolagem) <- 
    if (length(AvioesDecolagem) > 0 & CP >= 2) {
        [PrimeiroAviao | AvioesRestantes] = AvioesDecolagem;
        .send(PrimeiroAviao, tell, decolar);
        .println("Autorizado decolagem para ", PrimeiroAviao);

        -avioes_para_decolar(AvioesDecolagem);
        +avioes_para_decolar(AvioesRestantes);

        -contador_pousos(CP);
        +contador_pousos(0);
        .wait(3000);
        !verificar_decolagem;
    } else {
        if (pousos_restantes(N) & N > 0) {
            .println("Aguardando mais pousos antes de iniciar a decolagem.");
            !avancar_tempo;
        } else {
            if (length(AvioesDecolagem) == 0) {
                .println("Todas as operacoes foram concluídas. Controlador finalizando atividades.");
                .stopMAS;
            } else {
                .println("Autorizando decolagens pendentes.");
                !autorizar_todas_decolagens;
            }
        }
    }.

+!verificar_decolagem : contador_pousos(CP) & CP < 2 <- 
    .println("Aguardando mais pousos antes de iniciar a decolagem.");
    !avancar_tempo.

+!atualizar_pousos_restantes(Aviao) <- 
    ?pousos_restantes(N);
    N1 = N - 1;
    -pousos_restantes(N);
    +pousos_restantes(N1);
    -proposta(Aviao, _, _);  // Remove qualquer proposta do avião
    ?avioes_pousados(Lista);
    ListaNova = [Aviao | Lista];
    -avioes_pousados(Lista);
    +avioes_pousados(ListaNova);
    +aviao_pousado(Aviao);
    ?contador_pousos(CP);
    CP1 = CP + 1;
    -contador_pousos(CP);
    +contador_pousos(CP1).

+!avancar_tempo : pousos_restantes(N) & avioes_para_decolar(AvioesDecolagem) <-
    if (N > 0 | length(AvioesDecolagem) > 0) {
        ?tempo_atual(T);
        !limpar_propostas(T);
        T1 = T + 1;
        -tempo_atual(T);
        +tempo_atual(T1);
        .broadcast(tell, tempo_atual(T1));
        !enviar_atualizacao_simulacao;
        !iniciar_pouso;
    } else {
        .println("Todas as operações foram concluídas. Controlador finalizando atividades.");
        !enviar_atualizacao_simulacao;
        .stopMAS;
    }.

+!limpar_propostas(T) <- 
    .abolish(proposta(_, _, T));  // Remove todas as propostas do tempo T
    .abolish(pending_cfp(_));  // Remove todas as mensagens CFP pendentes
    -propostas_processadas(_);
    +propostas_processadas([]);
    -melhor_aviao(_).

+!notificar_avioes(T) <- 
    .broadcast(cfp, ["quem_quer_pousar", T]);  // Envia o tempo atual junto com o CFP
    .println("CFP enviado para avioes no tempo ", T).

+!aguardar_todas_propostas(T) <- 
    .println("Aguardand vencedor para o tempo ", T);
    .wait(2000).  // Ajusta o tempo de espera conforme necessário

+!kqml_received(Aviao, propose, [C], _) : tempo_atual(TA) & not aviao_pousado(Aviao) <- 
    if (not member(Aviao, propostas_processadas)) {
        +proposta(Aviao, C, TA);
        .println("Recebida proposta de ", Aviao, " com gasolina: ", C, " no tempo ", TA);
        +propostas_processadas(Aviao); // Adiciona o avião à lista de propostas processadas
    } else {
        .println("Proposta duplicada de ", Aviao, " ignorada.");
    }.

+!encontrar_melhor_aviao(T) : proposta(MelhorAviao, MenorC, T) <- 
    !comparar_propostas(MelhorAviao, MenorC, T).

+!encontrar_melhor_aviao(T) : not proposta(_, _, T) <- 
    .println("Nenhuma proposta recebida no tempo ", T);
    !avancar_tempo.

+!comparar_propostas(AtualAviao, AtualC, T) : proposta(Aviao, C, T) & C < AtualC <- 
    !comparar_propostas(Aviao, C, T).

+!comparar_propostas(MelhorAviao, MenorC, T) : not (proposta(_, C, T) & C < MenorC) <- 
    +melhor_aviao(MelhorAviao);  
    .println("Aviao selecionado para pousar: ", MelhorAviao, " com gasolina: ", MenorC, " no tempo ", T).

+!kqml_received(Sender, ILF, Content, MsgID) <- 
    .println("Controlador recebeu mensagem de ", Sender, " com ILF ", ILF, " e conteudo ", Content).

+!autorizar_todas_decolagens : avioes_para_decolar(AvioesDecolagem) <- 
    if (AvioesDecolagem & length(AvioesDecolagem) > 0) {
        [PrimeiroAviao | AvioesRestantes] = AvioesDecolagem;
        .send(PrimeiroAviao, tell, decolar);
        .println("Autorizado decolagem para ", PrimeiroAviao);

        -avioes_para_decolar(AvioesDecolagem);
        +avioes_para_decolar(AvioesRestantes);

        .wait(3000);
        !autorizar_todas_decolagens;
    } else {
        .println("Todas as decolagens pendentes foram autorizadas.");
        .println("Todas as operacoes foram concluidas. Controlador finalizando atividades.");
        .kill_agent("controller");  // Termina o agente controlador
    }.

+!enviar_atualizacao_simulacao <- 
    ?avioes_pousados(AvioesPousados);
    ?avioes_para_decolar(AvioesDecolagem);
    ?tempo_atual(T);
    ?pousos_restantes(N);
    !calcular_avioes_no_ar;
    ?avioes_no_ar(AvioesNoAr);
    !converter_lista_para_strings(AvioesPousados, AvioesPousadosStr);
    !converter_lista_para_strings(AvioesDecolagem, AvioesDecolagemStr);
    !converter_lista_para_strings(AvioesNoAr, AvioesNoArStr);
    sendUpdateToSimulation(T, N, AvioesPousadosStr, AvioesDecolagemStr, AvioesNoArStr);
    .println("Atualizacao enviada para a simulacao: Tempo=", T, ", PousosRestantes=", N, ", AvioesPousados=", AvioesPousadosStr, ", AvioesParaDecolar=", AvioesDecolagemStr, ", AvioesNoAr=", AvioesNoArStr).

+!kqml_received(Sender, ILF, Content, MsgID) <-
    .println("Controlador recebeu mensagem de ", Sender, " com ILF ", ILF, " e conteudo ", Content);
    !enviar_atualizacao_simulacao.

+!converter_lista_para_strings([], []) <- 
    true.

+!converter_lista_para_strings([Elemento | Resto], [ElementoStr | ResultadoResto]) <- 
    .concat("", Elemento, ElementoStr);  // Concatena para garantir que seja uma string
    !converter_lista_para_strings(Resto, ResultadoResto).

+!converter_lista_para_strings(NaN, _) <- 
    .println("Erro: Tentativa de converter NaN para lista de strings.").

+!calcular_avioes_no_ar : true <- 
    ?tempo_atual(T);
    ?avioes_pousados(AvioesPousados);
    ?avioes_para_decolar(AvioesDecolagem);
    Avioes = [aviao(plane1, 1), aviao(plane2, 1), aviao(plane3, 1), aviao(plane4, 2), aviao(plane5, 2), aviao(plane6, 3)];
    !filtrar_avioes_no_ar(Avioes, AvioesPousados, AvioesDecolagem, T, []).
    
+!filtrar_avioes_no_ar([], _, _, _, Resultado) <- 
    -avioes_no_ar(_);  // Remove crença anterior
    +avioes_no_ar(Resultado);  // Adiciona nova crença
    .println("Aviões no ar no tempo ", TempoAtual, ": ", Resultado).

+!filtrar_avioes_no_ar([aviao(Aviao, TC) | Resto], Pousados, Decolagem, TempoAtual, Parcial) 
    : .compare("=<", TC, TempoAtual) & not(member(Aviao, Pousados)) & not(member(Aviao, Decolagem)) <- 
    !filtrar_avioes_no_ar(Resto, Pousados, Decolagem, TempoAtual, [Aviao | Parcial]).

+!filtrar_avioes_no_ar([_ | Resto], Pousados, Decolagem, TempoAtual, Parcial) <- 
    !filtrar_avioes_no_ar(Resto, Pousados, Decolagem, TempoAtual, Parcial).

