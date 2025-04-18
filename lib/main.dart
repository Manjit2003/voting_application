import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'services/wallet_service.dart';
import 'services/web3_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final walletService = WalletService();
  final web3Service = Web3Service();

  await Future.wait([
    walletService.init(),
    web3Service.init(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletService),
        Provider.value(value: web3Service),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting App'),
        actions: const [
          WalletConnectButton(),
        ],
      ),
      body: Consumer<WalletService>(
        builder: (context, wallet, child) {
          if (!wallet.isConnected) {
            return const Center(
              child: Text('Please connect your wallet to continue'),
            );
          }

          return const VotingScreen();
        },
      ),
    );
  }
}

class WalletConnectButton extends StatelessWidget {
  const WalletConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, wallet, child) {
        if (wallet.isConnected) {
          return PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'disconnect',
                child: const Text('Disconnect'),
                onTap: () => wallet.disconnect(),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${wallet.address.substring(0, 6)}...${wallet.address.substring(wallet.address.length - 4)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return TextButton(
          onPressed: () => wallet.connect(),
          child: const Text('Connect Wallet'),
        );
      },
    );
  }
}

class VotingScreen extends StatelessWidget {
  const VotingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final web3 = Provider.of<Web3Service>(context, listen: false);
    final wallet = Provider.of<WalletService>(context, listen: false);

    return FutureBuilder<bool>(
      future: web3.hasVoted(wallet.address as EthereumAddress),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final hasVoted = snapshot.data ?? false;
        if (hasVoted) {
          return const Center(child: Text('You have already voted'));
        }

        return const CandidateList();
      },
    );
  }
}

class CandidateList extends StatelessWidget {
  const CandidateList({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement candidate list and voting UI
    return const Center(child: Text('Candidate list will be shown here'));
  }
}
