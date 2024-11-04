package env;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

import org.json.JSONArray;
import org.json.JSONObject;

import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;

public class SimulationInterface extends Artifact {

    private int fileCounter = 0;
    private boolean isConnected = false;
    private ServerSocket serverSocket;
    private Socket clientSocket;
    private PrintWriter out;
    private BufferedReader in;

    void init() {
        isConnected = true;
        startServer();
    }

    @OPERATION
    void sendUpdateToSimulation(int tempoAtual, int pousosRestantes, Object[] avioesPousadosArray, Object[] avioesParaDecolarArray, Object[] avioesNoArArray) {
        try {
            String content = new String(Files.readAllBytes(Paths.get("src/env/planesData.json")), StandardCharsets.UTF_8);
            JSONObject jsonObj = new JSONObject(content);
            JSONArray planesArray = jsonObj.getJSONArray("planes");

            JSONArray avioesNoAr = new JSONArray();
            for (int i = 0; i < planesArray.length(); i++) {
                JSONObject planeObj = planesArray.getJSONObject(i);
                int tempoChegada = planeObj.getInt("tempo");

                if (tempoChegada <= tempoAtual) {
                    String planeId = planeObj.getString("id");
                    if (!arrayContains(avioesPousadosArray, planeId)) {
                        avioesNoAr.put(planeId);
                    }
                }
            }

            JSONArray avioesPousados = new JSONArray();
            for (Object o : avioesPousadosArray) {
                avioesPousados.put(o.toString());
            }

            JSONArray avioesParaDecolar = new JSONArray();
            for (Object o : avioesParaDecolarArray) {
                avioesParaDecolar.put(o.toString());
            }

            JSONObject json = new JSONObject();
            json.put("tempo_atual", tempoAtual);
            json.put("pousos_restantes", pousosRestantes);
            json.put("avioes_pousados", avioesPousados);
            json.put("avioes_para_decolar", avioesParaDecolar);
            json.put("avioes_no_ar", avioesNoAr);

            writeJsonToFile(json);

            if (out != null) {
                out.println(json.toString());
                out.flush();
            }

            signal("dataSent", json);

        } catch (IOException e) {
            failed("Erro ao carregar o arquivo planesData.json: " + e.getMessage());
        } catch (Exception e) {
            failed("Erro ao processar dados: " + e.getMessage());
        }
    }

    private void startServer() {
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(12345);
                System.out.println("Servidor iniciado na porta 12345. Aguardando conexões...");
                
                clientSocket = serverSocket.accept();
                System.out.println("Conexão estabelecida com Unity.");
                
                OutputStream outputStream = clientSocket.getOutputStream();
                out = new PrintWriter(outputStream, true);

                InputStreamReader inputStream = new InputStreamReader(clientSocket.getInputStream(), StandardCharsets.UTF_8);
                in = new BufferedReader(inputStream);

                listenForUnityMessages();

            } catch (IOException e) {
                System.err.println("Erro ao iniciar o servidor: " + e.getMessage());
            }
        }).start();
    }

    private void listenForUnityMessages() {
        new Thread(() -> {
            String line;
            try {
                while ((line = in.readLine()) != null) {
                    System.out.println("Mensagem recebida da Unity: " + line);
                    JSONObject receivedJson = new JSONObject(line);

                    // Aqui você pode processar o JSON recebido
                    processUnityData(receivedJson);
                }
            } catch (IOException e) {
                System.err.println("Erro ao ler dados da Unity: " + e.getMessage());
            }
        }).start();
    }

    private void processUnityData(JSONObject receivedJson) {
        // Exemplo de processamento dos dados recebidos
        // Você pode manipular o JSON para atualizar o ambiente de simulação conforme necessário
        int tempo = receivedJson.getInt("tempo");
        JSONArray avioes = receivedJson.getJSONArray("avioes");

        // Processa os dados conforme necessário
        System.out.println("Tempo recebido: " + tempo);
        System.out.println("Aviões recebidos: " + avioes.toString());

        // Atualiza o ambiente ou sinaliza o que for necessário no sistema multiagente
        signal("unityDataReceived", receivedJson);
    }

    private boolean arrayContains(Object[] array, String element) {
        for (Object obj : array) {
            if (obj.toString().equals(element)) {
                return true;
            }
        }
        return false;
    }

    private void writeJsonToFile(JSONObject json) {
        try {
            String filename = "simulation_data_" + fileCounter + ".json";
            fileCounter++;
            FileWriter file = new FileWriter(filename);
            file.write(json.toString(4));
            file.flush();
            file.close();
            System.out.println("JSON escrito no arquivo: " + filename);
        } catch (IOException e) {
            System.err.println("Erro ao escrever JSON no arquivo: " + e.getMessage());
        }
    }

    @INTERNAL_OPERATION
    void emitSignalWithDelay() {
        await_time(1000);
        signal("simulationConnected");
    }
}