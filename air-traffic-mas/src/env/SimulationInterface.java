package env;

import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import org.json.JSONArray;
import org.json.JSONObject;

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
    void sendUpdateToSimulation(int tempoAtual, int pousosRestantes, Object[] avioesPousadosArray, Object[] avioesParaDecolarArray) {
        try {
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

            writeJsonToFile(json);

            signal("dataSent", json);
        } catch (Exception e) {
            failed("Erro ao processar dados: " + e.getMessage());
        }
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