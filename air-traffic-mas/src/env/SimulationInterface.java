package env;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

import org.json.JSONArray;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;
import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import jason.asSyntax.ListTerm;
import jason.asSyntax.Literal;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.Structure;
import jason.asSyntax.Term;

public class SimulationInterface extends Artifact {

    private int fileCounter = 0;
    private boolean isConnected = false;

        void init() {
        isConnected = true;
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

            signal("dataSent", json);

        } catch (IOException e) {
            failed("Erro ao carregar o arquivo planesData.json: " + e.getMessage());
        } catch (Exception e) {
            failed("Erro ao processar dados: " + e.getMessage());
        }
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

// cenários:
// 8 aviões (variavel)
// com mais aviões chegando do que decolando -> avioes com mesma caracteristicas de gasolina e prioridade.
// com mais aviões decolando do que chegando -> avioes com mesma caracteristicas de gasolina e prioridade.
// cenário totalmente aleatório (absurdo)