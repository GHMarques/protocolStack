<?php
	if(isset($_POST['submit'])){
		//get form values
		$strMask = $_POST['mask'];
		$strDns = $_POST['dns'];
		$strRouter = $_POST['router'];

		//create config file
		$strFileName = '../file/server_config.txt';
		$file = fopen($strFileName, 'w') or die('Cannot open file:  '.$strFileName);

		//create string
		$strData = $strMask . "\n" . $strDns . "\n" . $strRouter;

		//write file
		fwrite($file, $strData);

		//close file
		fclose($file);

		//popup alert
		echo "<script>alert('DHCP config successfully saved');</script>";
	}
?>

<html>
	<head>
		<title>DHCP</title>
		<link rel="stylesheet" href="styles.css">
	</head>
	<body>
		<div class="center">
			<h1>DHCP Configuration</h1>
			<div class="container">
				<form action="server_config.php" method="post" name="formDhcp">
					<p>Subnet mask: <input type="text" name="mask" /></p>
					<p>DNS IP: <input type="text" name="dns" /></p>
					<p>Router IP: <input type="text" name="router" /></p>
					<p><input type="submit" value="Submit" name="submit"/></p>
				</form>
			</div>
		</div>
		
	</body>
</html>

