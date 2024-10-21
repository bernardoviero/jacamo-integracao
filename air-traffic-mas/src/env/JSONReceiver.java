package env;

import cartago.*;
import jason.asSyntax.*;
import org.json.JSONObject;
import org.json.JSONArray;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.io.InputStream;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;

public class JSONReceiver extends Artifact {

    private Map<String, JSONObject> planesData = new HashMap<>();

    void init() {
        loadPlanesData();
    }

    private void loadPlanesData() {
        try {
            String content = new String(Files.readAllBytes(Paths.get("src/env/planesData.json")), StandardCharsets.UTF_8);

            JSONObject jsonObj = new JSONObject(content);
            JSONArray planesArray = jsonObj.getJSONArray("planes");

            for (int i = 0; i < planesArray.length(); i++) {
                JSONObject planeObj = planesArray.getJSONObject(i);
                String id = planeObj.getString("id");
                planesData.put(id, planeObj);
            }

            System.out.println("Dados carregados.");

        } catch (IOException e) {
            System.err.println("Erro ao ler planesData.json: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Error ao converter planesData.json: " + e.getMessage());
        }
    }

    @OPERATION
    void getData(String planeId, OpFeedbackParam<Literal> data) {
        if (planesData.containsKey(planeId)) {
            JSONObject jsonObject = planesData.get(planeId);

            String id = jsonObject.getString("id");
            float altitude = jsonObject.getFloat("altitude");
            float posicao = jsonObject.getFloat("posicao");
            int escala = jsonObject.getInt("escala");
            int gasolina = jsonObject.getInt("gasolina");
            int tempo = jsonObject.getInt("tempo");

            Term idTerm = ASSyntax.createString(id);
            Term altitudeTerm = ASSyntax.createNumber(altitude);
            Term posicaoTerm = ASSyntax.createNumber(posicao);
            Term escalaTerm = ASSyntax.createNumber(escala);
            Term gasolinaTerm = ASSyntax.createNumber(gasolina);
            Term tempoTerm = ASSyntax.createNumber(tempo);

            Literal result = ASSyntax.createLiteral("dados", idTerm, altitudeTerm, posicaoTerm, escalaTerm, gasolinaTerm, tempoTerm);

            data.set(result);
        } else {
            String errorMsg = "Plane ID não encontrado: " + planeId;
            System.err.println(errorMsg);
            failed(errorMsg);
        }
    }

    @OPERATION
    void reloadData() {
        loadPlanesData();
        signal("dataReloaded");
        System.out.println("dados carregados novamente.");
    }
}