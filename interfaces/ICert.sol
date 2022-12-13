    enum CertState {
        Deleted,Using
    }
    interface ICert{
        function user_cert_state(address user,string memory cert) external view returns(CertState);
    }
