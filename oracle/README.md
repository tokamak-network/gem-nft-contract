# Staking Index Oracle

## description

This script is an event listener which catches events ```Deposited``` and ```WithdrawalRequested``` emitted in L1WrappedStakedTON. the script is made to run within a docker container. To ensure the private key is safe, we make sure it is encrypted using KMS feature from AWS. 

## Installation

