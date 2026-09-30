# -*- coding: utf-8 -*-
import json

data = {
    "subtitle": "Emparella quadres i plaques",
    "description": (
        "CR Way és un carril d'emparellament del Museu d'Art de Filadèlfia per a qui vol aquest emparellament en aquest dispositiu, no un recorregut pel museu, ni una botiga ni un compte. Deses pintures i després penges cada tela en espera sota la placa que la nomena, per autor o per títol.\n"
        "\n"
        "• Desa pintures del Museu d'Art de Filadèlfia des d'Explora, amb un prestatge local quan la cerca és quieta o falla.\n"
        "• Cerca al museu per Autor o títol.\n"
        "• Conserva una obra que ja és al carril sense afegir-la dues vegades.\n"
        "• Explora sempre té un prestatge local de vuit pintures: La clínica Gross de Thomas Eakins, Nu baixant una escala núm. 2 de Marcel Duchamp, El regne pacífic d'Edward Hicks, Prometeu encadenat de Peter Paul Rubens, L'Anunciació de Henry Ossawa Tanner, Dona amb un collaret de perles en una llotja de Mary Cassatt, L'incendi de les Cases dels Lords i dels Comuns de Joseph Mallord William Turner, i L'artista al seu museu de Charles Willson Peale.\n"
        "• Extén tres obres en espera en un carril amb tres plaques.\n"
        "• Les plaques d'un trio són totes d'autors o totes de títols (Les plaques mostren l'autor o Les plaques mostren el títol).\n"
        "• Aixeca una tela en espera i després col·loca-la sota la placa que la nomena.\n"
        "• Col·loca aquesta pintura col·loca la tela en espera o alçada sota la placa que la nomena.\n"
        "• Una placa incorrecta és una errada: Errada, prova'n una altra. La tela torna a En espera, i l'errada va a Desat com a Caiguda.\n"
        "• Una placa correcta col·loca la tela com a Enganxat (Ja col·locat en aquesta placa).\n"
        "• Tres col·locacions correctes resolen el trio (Carril resolt.). Aquestes tres passen a Desat com a Col·locat.\n"
        "• Extén el següent penja el trio següent quan tres obres esperen.\n"
        "• Retreu la marca més nova lleva el ganxo o la caiguda més nova des de l'inici o Configuració.\n"
        "• Desat llista Col·locats, Ganxos i Caigudes.\n"
        "• Ganxos recents i Caigudes a Desat al carril d'inici.\n"
        "• Torna a recórrer les pàgines i Esborra el carril.\n"
        "• Contacte, Museu d'Art de Filadèlfia i Crèdit d'accés obert.\n"
        "• Dreceres: Obre Qüestionari, Obre Explora, Obre Desat, Obre Configuració, Extén el carril, Aixeca una tela, Enganxa una placa.\n"
        "\n"
        "Les obres desades, els ganxos i les caigudes resten en aquest dispositiu."
    ),
    "keywords": "museu,pintura,Filadèlfia,placa,emparellar,tela,ganxo,desat,explorar,art,carril,autor,títol,quadre",
    "promotional_text": "Desa una pintura del museu i enganxa-la sota la placa que la nomena. Les errades resten a Desat. Retreu lleva la marca més nova.",
    "release_notes": (
        "Aquesta és la versió 1.0, el primer llançament de CR Way.\n"
        "\n"
        "CR Way és un carril d'emparellament del Museu d'Art de Filadèlfia. Deses pintures des d'Explora i després penges cada tela en espera sota la placa que la nomena, per autor o per títol.\n"
        "\n"
        "Aquest llançament inclou Explora amb cerca per Autor o títol, Desa, Conserva i un prestatge local de vuit pintures; un carril d'inici per estendre tres obres en espera i col·locar-les sota les plaques; Col·loca aquesta pintura, Ganxos recents, Caigudes a Desat i Retreu la marca més nova; seccions de Desat Col·locats, Ganxos i Caigudes; Configuració amb Museu d'Art de Filadèlfia, Crèdit d'accés obert, Contacte, Torna a recórrer les pàgines i Esborra el carril; tres pàgines d'introducció Col·loca cada tela, Aixeca, després enganxa, i Conserva el carril; i dreceres Obre Qüestionari, Obre Explora, Obre Desat, Obre Configuració, Extén el carril, Aixeca una tela i Enganxa una placa.\n"
        "\n"
        "Només en anglès. Orientació vertical i aparença clara. iPhone i iPad. iOS 17.0 com a mínim. Les obres desades, els ganxos i les caigudes resten en aquest dispositiu."
    ),
}

limits = {
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "release_notes": 4000,
}

ok = True
for k, lim in limits.items():
    n = len(data[k])
    flag = "OK" if n <= lim else "OVER"
    if n > lim:
        ok = False
    print(f"{flag} {k}: {n}/{lim}")

kw = data["keywords"]
assert "," in kw and " " not in kw
assert "CR" not in kw and "Way" not in kw
print("keywords commas-ok, no spaces, no app name")
print("JSON_OK" if ok else "JSON_BAD")
print(json.dumps(data, ensure_ascii=False, indent=2))
