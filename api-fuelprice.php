<?php
#Set charset => ä/ö/ü will be displayed
header("Content-Type: text/html; charset=utf-8");

#Version 1.0

## Config ## 

#Postleitzahl
$plz = "31848";

#Spritsorte
#Super E5 = 7
#Super E10 = 5
#Diesen = 3
#Autogas = 1
$spritsorte = "7";

#Umkreis in KM
#Mögliche Optionen: 1,2,5,10,20,25 Kilometer
$radius = "5";

## Config End ##



## Script ##
$url = "http://www.clever-tanken.de/tankstelle_liste?spritsorte=$spritsorte&r=$radius&ort=$plz";
$html = file_get_contents($url);

#minimize Output
$html = explode('Karte', $html);
$html = explode('main-content-footer', $html[1]);
$html = preg_replace('/<[^>]*>/', "", $html[0]);
$html = preg_replace('/\s*\([^)]*\)/', '', $html);
$html = str_replace(".push;", "", $html);
$html = preg_replace('/\s+/', ' ', $html);

#Tankstellen voneinander trennen
$array = explode("-->-->", $html);

#Zur Überprüfung ob überhaupt Tankstellen offen haben
$counter = 0;

foreach ($array as $value => $key) 
{
	#Nur Tankstellen anzeigen, die geöffnet haben
	if(substr($key, 0, 2) == "1.") #1. Steht für 1€ + z.B. 24 (1,24€)
	{	
		$counter++; #Zur Überprüfung ob überhaupt Tankstellen offen haben
		
		$preis = explode(" ", $key);
		$adresse = explode("-->", $key);

		#Preis übergeben
 		$data[$value]['preis'] = $preis[1];

 		#Entfernung aus Adresse entfernen
		$entf = substr($adresse[1], -8);
		#Adresse übergeben
 		$data[$value]['adresse'] = trim(str_replace($entf, "", $adresse[1]));
	}
}

#Temporäre Meldung
if($counter == 0) {
	echo "Alle Tankstellen in der N&auml;he geschlossen!";
}

#Ausgabe nur wenn Tankstellen geöffnet
if($counter != 0 and !empty($data))
{
?>
	<table>
	<tr>
		<th>Tankstelle</th>
		<th>Preis</th>
	</tr>
	<?php 
		foreach ($data as $wert) 
		{
			echo "<tr><td>";
			echo $wert['adresse'];
			echo "</td><td>";
			echo $wert['preis'] . " &euro;";
			echo "</td></tr>";
		}
	 ?>
	 </table>
<?php
}
?>