    enum CertState {
        Deleted,Using
    }
    struct certRetInfo{
        uint256 createTime;
        uint256 remainTime;
        address user;
        CertState state;
        string cert;
        uint256 index;
    }
    interface ICert{
        function user_cert_state(address user,string memory cert) external view returns(CertState);
        function getUserCert(address user,uint256 index)external view returns(certRetInfo memory);
    }
