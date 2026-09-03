package com.works.repositories;

import com.works.entities.Product;
import com.works.entities.Storage;
import com.works.entities.Vaccine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface StorageRepository extends JpaRepository<Storage, Integer> {

    // Gönderilen vaccine ait depo işlemleri
    @Query(value = "select * from Storage where upper(stvac) = upper(?1) order by stid DESC LIMIT 6", nativeQuery = true)
    List<Storage> findByStvacEqualsAllIgnoreCaseOrderByStidDesc(Vaccine stvac);

    // Gönderilen product ait depo işlemleri
    @Query(value = "select * from Storage where upper(stpro) = upper(?1) order by stid DESC LIMIT 6", nativeQuery = true)
    List<Storage> findByStproEqualsAllIgnoreCaseOrderByStidDesc(Product product);

    // Depo Ürünleri - en son kayıt için her vaccine/product kombinasyonunu getirir
    @Query(value = "SELECT s.* " +
            "FROM storage s " +
            "INNER JOIN (" +
            "    SELECT stvac, stpro, MAX(stid) AS max_stid " +
            "    FROM storage " +
            "    GROUP BY stvac, stpro" +
            ") x ON s.stid = x.max_stid " +
            "ORDER BY s.stid DESC", nativeQuery = true)
    List<Storage> findByOrderByStidDesc();

    // Son 10 Depo işlemini sıralama
    @Query(value = "select * from Storage order by stdate DESC LIMIT 10", nativeQuery = true)
    List<Storage> findByOrderByStdateDesc();

    // Depo Ürünleri Toplam
    @Query(value = "SELECT SUM(stlastamount) from storage", nativeQuery = true)
    long sumlastamount();

}