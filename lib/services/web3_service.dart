import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Web3Service {
  late final Web3Client _web3client;
  late final String _rpcUrl;
  late final String _wsUrl;
  late final EthereumAddress _votingSystemAddress;
  late final EthereumAddress _votingTokenAddress;
  late final DeployedContract _votingSystemContract;
  late final DeployedContract _votingTokenContract;

  Web3Service._();
  static final Web3Service _instance = Web3Service._();
  factory Web3Service() => _instance;

  Future<void> init() async {
    await dotenv.load();
    _rpcUrl = dotenv.env['RPC_URL'] ?? '';
    _wsUrl = dotenv.env['WS_URL'] ?? '';
    _votingSystemAddress = EthereumAddress.fromHex(
      dotenv.env['VOTING_SYSTEM_ADDRESS'] ?? '',
    );
    _votingTokenAddress = EthereumAddress.fromHex(
      dotenv.env['VOTING_TOKEN_ADDRESS'] ?? '',
    );

    final client = http.Client();
    _web3client = Web3Client(_rpcUrl, client);

    // Load contract ABIs
    final votingSystemAbi =
        await rootBundle.loadString('assets/VotingSystem.json');
    final votingTokenAbi =
        await rootBundle.loadString('assets/VotingToken.json');

    _votingSystemContract = DeployedContract(
      ContractAbi.fromJson(votingSystemAbi, 'VotingSystem'),
      _votingSystemAddress,
    );

    _votingTokenContract = DeployedContract(
      ContractAbi.fromJson(votingTokenAbi, 'VotingToken'),
      _votingTokenAddress,
    );
  }

  // Admin Functions
  Future<String> addCandidate(String name, Credentials credentials) async {
    final function = _votingSystemContract.function('addCandidate');
    final result = await _web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: _votingSystemContract,
        function: function,
        parameters: [name],
      ),
      chainId: null,
    );
    return result;
  }

  // Voter Functions
  Future<String> castVote(BigInt candidateId, Credentials credentials) async {
    final function = _votingSystemContract.function('castVote');
    final result = await _web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: _votingSystemContract,
        function: function,
        parameters: [candidateId],
      ),
      chainId: null,
    );
    return result;
  }

  // View Functions
  Future<List<dynamic>> getCandidate(BigInt candidateId) async {
    final function = _votingSystemContract.function('getCandidate');
    final result = await _web3client.call(
      contract: _votingSystemContract,
      function: function,
      params: [candidateId],
    );
    return result;
  }

  Future<BigInt> getVoteBalance(EthereumAddress address) async {
    final function = _votingTokenContract.function('balanceOf');
    final result = await _web3client.call(
      contract: _votingTokenContract,
      function: function,
      params: [address],
    );
    return result.first as BigInt;
  }

  Future<bool> hasVoted(EthereumAddress address) async {
    final function = _votingSystemContract.function('hasVoted');
    final result = await _web3client.call(
      contract: _votingSystemContract,
      function: function,
      params: [address],
    );
    return result.first as bool;
  }
}
