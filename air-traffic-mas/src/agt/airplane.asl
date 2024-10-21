include('std_agents').

!start.

tempo_atual(0).  // Crença inicial do tempo atual
pousado(false).  // O avião começa como não pousado
proposta_enviada(false).  // Estado para verificar se a proposta foi enviada

+!start <- 
    joinWorkspace(w);  
    lookupArtifact(jsonReceiver, ID);  
    focus(ID);
    !obterDados.

+!obterDados <- 
    .my_name(AgentName);
    .println("Agente: ", AgentName);
    .println("Obtendo dados do artefato...");
    getData(AgentName, Dados);
    .println("Dados recebidos: ", Dados);
    Dados = dados(Id, Altitude, Posicao, Escala, Gasolina, Tempo);
    +id(Id);
    +altitude(Altitude);
    +posicao(Posicao);
    +escala(Escala);
    +gasolina(Gasolina);
    +tempo_chegada(Tempo);
    .println("Crencas atualizadas: id(", Id, "), altitude(", Altitude, "), posicao(", Posicao, "), escala(", Escala, "), gasolina(", Gasolina, "), tempo_chegada(", Tempo, ").");
    .wait(4000);
    !aguardar_tempo_chegada.

+!aguardar_tempo_chegada : tempo_chegada(TC) & tempo_atual(TA) & TA < TC <- 
    .println("Aguardando tempo de chegada ", TC, ". Tempo atual: ", TA);
    .wait(1000);
    !aguardar_tempo_chegada.

+!aguardar_tempo_chegada : tempo_chegada(TC) & tempo_atual(TA) & TA >= TC <- 
    .println("Tempo de chegada alcancado. Iniciando operacoes.");
    !processar_mensagens_pendentes.

+!processar_mensagens_pendentes : pousado(false) & pending_cfp(MsgID) & gasolina(C) & tempo_atual(TA) & tempo_chegada(TC) & TA >= TC <- 
    if (not proposta_enviada) {
        .send(controller, propose, [C]);
        -pending_cfp(MsgID);
        .println("Enviada proposta ao controlador com gasolina: ", C);
        +proposta_enviada(true);  // Marca que uma proposta foi enviada
        .wait(1000);
    } else {
        .println("Proposta ja enviada por ", AgentName, " e não sera reenviada.");
    }.

+!processar_mensagens_pendentes : pousado(true) <- 
    .println("O avião ja pousou e nao pode enviar propostas.").

+!processar_mensagens_pendentes : true <- 
    .println("Nao ha mensagens pendentes para processar.").

+!kqml_received(controller, cfp, ["quem_quer_pousar", T], MsgID) <- 
    +pending_cfp(MsgID);
    .println("Mensagem CFP recebida de ", controller, " e armazenada.");
    -proposta_enviada(false); 
    .println("Resetando proposta_enviada para false apos receber CFP.");
    !processar_mensagens_pendentes.

+!kqml_received(controller, tell, pouso_aprovado, _) <- 
    .my_name(AgentName);
    .println(AgentName, " esta iniciando o pouso");
    .wait(3000);
    .println(AgentName, " pousou com sucesso.");
    -+pousado(true);
    if (escala(1)) {
        !esperar_para_decolar;  // Se escala = 1, ele precisa decolar depois
    } else {
        .println(AgentName, " nao possui escala. Encerrando agente.");
        .kill_agent(AgentName);  // Termina o agente
    }.
    .println(AgentName, " não enviara mais propostas.").

+!esperar_para_decolar <- 
    .println("Aguardando tempo para decolar...");
    .wait(5000);  // Espera o tempo necessário antes de solicitar a decolagem
    .send(controller, tell, decolagem_solicitada);
    .println("Solicitando decolagem apos pouso.").

+!kqml_received(controller, tell, decolar, _) <- 
    .my_name(AgentName);
    .println(AgentName, " esta decolando agora.").